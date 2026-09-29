"""Verify the Nix-owned app bundles after Home Manager activation on macOS."""
import argparse
import json
import os
import signal
import tempfile
import platform
import plistlib
from pathlib import Path
import subprocess


def smoke_launch(executable):
    # Run the copied executable, never an existing Homebrew/Launch Services app.
    # A surviving process is a startup smoke test, not a UI or login test.
    with tempfile.TemporaryFile() as log:
        process = subprocess.Popen(
            [str(executable)], stdout=log, stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        try:
            try:
                code = process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                print(f"Startup smoke test passed: {executable}", flush=True)
            else:
                log.seek(0)
                output = log.read().decode(errors="replace")
                raise RuntimeError(f"App exited during startup ({code}): {executable}\n{output}")
        finally:
            # Include child helpers spawned by Electron; never kill by app name.
            try:
                os.killpg(process.pid, signal.SIGTERM)
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                pass
            except ProcessLookupError:
                pass
            finally:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()


def check_apps(manifest, installed, profile, launch=False):
    if platform.system() != "Darwin":
        raise RuntimeError("This check requires macOS")
    architecture = platform.machine()
    for name in json.loads(manifest.read_text()):
        source = profile / "Applications" / name
        app = installed / name
        if not str(source.resolve()).startswith("/nix/store/"):
            raise RuntimeError(f"App is not supplied by Nix: {source}")
        if not app.is_dir() or app.is_symlink():
            raise RuntimeError(f"Home Manager did not copy the app bundle: {app}")
        with (source / "Contents/Info.plist").open("rb") as stream:
            expected = plistlib.load(stream)
        with (app / "Contents/Info.plist").open("rb") as stream:
            actual = plistlib.load(stream)
        for key in ("CFBundleIdentifier", "CFBundleExecutable", "CFBundleVersion"):
            if not actual.get(key) or actual[key] != expected.get(key):
                raise RuntimeError(f"Unexpected {key} in {app}")
        executable = app / "Contents/MacOS" / actual["CFBundleExecutable"]
        subprocess.run(["/usr/bin/lipo", "-verify_arch", architecture, str(executable)], check=True)
        # Verifies integrity after copying, including nested frameworks/helpers.
        # Does not claim that login, TCC permissions or VM startup have been tested.
        subprocess.run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)], check=True)
        print(f"Verified {name}: {actual['CFBundleVersion']} ({architecture})", flush=True)
        if launch and name in {"Ghostty.app", "Notion Calendar.app", "JupyterLab.app"}:
            smoke_launch(executable)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("installed", type=Path)
    parser.add_argument("profile", type=Path)
    parser.add_argument("--launch", action="store_true")
    check_apps(**vars(parser.parse_args()))
