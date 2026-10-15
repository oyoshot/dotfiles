#!/bin/sh
# Install Nix first: https://nix.dev/install-nix#multi-user-installation
# Initialize the local entry with Nix's template support:
#   mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/home-manager"
#   cd "${XDG_CONFIG_HOME:-$HOME/.config}/home-manager"
#   nix flake init -t /path/to/dotfiles#home
# Edit machine.nix, then run this script with --build before --switch.
# Local development (does not rewrite the machine's lock file):
#   home-manager build --flake "$NH_HOME_FLAKE#home" \
#     --override-input dotfiles /path/to/dotfiles --no-write-lock-file
set -eu
case "${1:---build}" in
    --build) action=build ;;
    --switch) action=switch ;;
    *) echo "Usage: sh scripts/setup-home.sh [--build|--switch]" >&2; exit 2 ;;
esac
source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
entry="${XDG_CONFIG_HOME:-$HOME/.config}/home-manager"
[ -f "$entry/flake.nix" ] || {
    echo "Initialize $entry with the home flake template and edit machine.nix first." >&2
    exit 1
}
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
nix --extra-experimental-features 'nix-command flakes' run "$source_dir#home-manager" -- \
    -b before-home-manager "$action" --flake "$entry#home"
if [ "$action" = switch ]; then
    echo "Home Manager applied. Next: sh $source_dir/scripts/bootstrap-host.sh"
fi
