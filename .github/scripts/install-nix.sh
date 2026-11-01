#!/bin/sh
# Latest official installer for disposable CI runners only.
set -eu

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM
curl --fail --location --retry 3 \
    https://nixos.org/nix/install -o "$temp_dir/install"
case "$(uname -s)" in
    Darwin)
        mode=--daemon
        ;;
    Linux)
        mode=--no-daemon
        ;;
    *) exit 1 ;;
esac
sh "$temp_dir/install" "$mode" --yes --no-channel-add --no-modify-profile

# Standalone Home Manager needs a profile directory before its first switch.
# Use the XDG location that our shell and CLI checks reference on both OSes.
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
