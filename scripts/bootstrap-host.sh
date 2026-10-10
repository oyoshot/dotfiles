#!/bin/sh
# Explicit provisioning for software and integration owned by the host OS.
# Run after Home Manager activation. Ordinary switches never run this script.
set -eu
source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export PATH="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/bin:/opt/homebrew/bin:$PATH"
case "$(uname -s)" in
    Darwin) sh "$source_dir/scripts/install-mac.sh" ;;
    Linux)
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ "$ID" = arch ]; then
            sh "$source_dir/scripts/install-arch.sh"
        fi
        ;;
esac
if [ "$(uname -s)" = Linux ]; then
    # Keep the build environment rooted: mise's Cargo binaries link its libraries.
    build_profiles="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
    mkdir -p "$build_profiles"
    nix develop --no-update-lock-file --profile "$build_profiles/runtime-build" \
        "$source_dir#native" --command zsh "$source_dir/scripts/install-runtimes.zsh"
else
    zsh "$source_dir/scripts/install-runtimes.zsh"
fi
if [ "$(uname -s)" = Linux ] && [ -e /dev/dxg ]; then
    sh "$source_dir/scripts/setup-wslg.sh"
fi
