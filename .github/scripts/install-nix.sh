#!/bin/sh
# Pinned official installer for disposable CI runners only.
set -eu

version=2.33.1
checksum=2bbe0d388d1bee5ee60ed67b844f428b6031a1b7c42d7d03319ad7133867290d
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM
curl --fail --location --retry 3 \
    "https://releases.nixos.org/nix/nix-$version/install" -o "$temp_dir/install"
case "$(uname -s)" in
    Darwin)
        actual=$(shasum -a 256 "$temp_dir/install" | cut -d ' ' -f 1)
        mode=--daemon
        ;;
    Linux)
        actual=$(sha256sum "$temp_dir/install" | cut -d ' ' -f 1)
        mode=--no-daemon
        ;;
    *) exit 1 ;;
esac
[ "$actual" = "$checksum" ] || { echo 'Nix installer checksum mismatch' >&2; exit 1; }
sh "$temp_dir/install" "$mode" --yes --no-channel-add --no-modify-profile
