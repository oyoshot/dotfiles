#!/bin/sh
set -eu

source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) configuration=oyoshot-linux ;;
    Darwin-arm64) configuration=oyoshot-darwin ;;
    *)
        echo "Unsupported Home Manager platform: $(uname -s)-$(uname -m)" >&2
        exit 1
        ;;
esac

for nix_dir in "$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin; do
    if [ -x "$nix_dir/nix" ]; then
        PATH="$nix_dir:$PATH"
        break
    fi
done
export PATH

nix --extra-experimental-features 'nix-command flakes' run \
    "$source_dir#home-manager" -- \
    switch --flake "$source_dir#$configuration"
