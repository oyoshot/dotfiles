#!/bin/sh
# Install Nix first: https://nix.dev/install-nix#multi-user-installation
# Initialize without cloning (choose wsl-linux, linux, or darwin):
#   nix run github:oyoshot/dotfiles/experiment/nix-cli#init -- wsl-linux
# On a host that edits this clone, follow its commits instead of GitHub:
#   nix run .#init -- --local . wsl-linux
# Updates (up) then pick up new commits; uncommitted changes leave the lock as is.
# Build and switch the generated entry with Home Manager before host provisioning.
set -eu
case "${1:---build}" in
    --build) action=build ;;
    --switch) action=switch ;;
    *) echo "Usage: sh scripts/setup-home.sh [--build|--switch]" >&2; exit 2 ;;
esac
source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
entry="${XDG_CONFIG_HOME:-$HOME/.config}/home-manager"
[ -f "$entry/flake.nix" ] || {
    echo "Initialize $entry with the dotfiles #init app first." >&2
    exit 1
}
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
nix --extra-experimental-features 'nix-command flakes' run "$source_dir#home-manager" -- \
    -b before-home-manager "$action" --flake "$entry#home"
if [ "$action" = switch ]; then
    echo "Home Manager applied. Next: nix run $source_dir#bootstrap-host"
fi
