"""Retire unchanged global mise defaults after their Nix replacements are linked."""
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

import tomlkit


def migrate(config: Path, names: list[str]) -> list[str]:
    if not config.exists():
        return []
    if config.is_symlink():
        raise ValueError(f"Expected mutable mise config, found symlink: {config}")
    original = config.read_text()
    document = tomlkit.parse(original)
    tools = document.get("tools", {})
    removed = [name for name in names if tools.get(name) == "latest"]
    if not removed:
        return []
    for name in removed:
        del tools[name]
    # Keep a unique backup on each actual change; repeated switches are no-ops.
    with tempfile.NamedTemporaryFile(prefix=config.name + ".before-nix-", dir=config.parent, delete=False) as backup:
        backup_path = Path(backup.name)
    shutil.copy2(config, backup_path)
    with tempfile.NamedTemporaryFile(mode="w", prefix=config.name + ".", dir=config.parent, delete=False) as output:
        temporary = Path(output.name)
        try:
            output.write(tomlkit.dumps(document))
            output.flush()
            os.fchmod(output.fileno(), config.stat().st_mode & 0o777)
            os.replace(temporary, config)
        finally:
            temporary.unlink(missing_ok=True)
    print(f"Moved mise defaults to Nix: {', '.join(removed)}; backup: {backup_path}")
    return removed


if __name__ == "__main__":
    migrate(Path(sys.argv[1]), json.loads(Path(sys.argv[2]).read_text()))
