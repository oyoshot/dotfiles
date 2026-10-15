#!/bin/sh
# First-time standalone Home Manager setup, after installing Nix.
# Official multi-user installation: https://nix.dev/install-nix#multi-user-installation
# Run --build first, then --switch, then scripts/bootstrap-host.sh.
set -eu

case "${1:---build}" in
    --build) action=build ;;
    --switch) action=switch ;;
    *) echo "Usage: sh scripts/setup-home.sh [--build|--switch]" >&2; exit 2 ;;
esac

if ! command -v nix >/dev/null 2>&1; then
    echo 'Install Nix using the official multi-user installer, then open a new shell:' >&2
    echo 'https://nix.dev/install-nix#multi-user-installation' >&2
    exit 1
fi

source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
case "$(uname -s)" in
    Linux) platform=linux ;;
    Darwin) platform=darwin ;;
    *) echo 'Unsupported operating system' >&2; exit 1 ;;
esac
configuration="$(id -un)-$platform"

# Check the selected profile before changing files in the user's home.
expected_home=$(nix --extra-experimental-features 'nix-command flakes' eval --raw \
    "$source_dir#homeConfigurations.$configuration.config.home.homeDirectory")
[ "$HOME" = "$expected_home" ] || {
    echo "Configuration $configuration expects HOME=$expected_home, found $HOME" >&2
    exit 1
}
expected_repo=$(nix --extra-experimental-features 'nix-command flakes' eval --raw \
    "$source_dir#homeConfigurations.$configuration.config.programs.nh.homeFlake")
[ "$source_dir" = "$expected_repo" ] || {
    echo "Move this checkout to $expected_repo before setup (preserve local changes and worktrees)." >&2
    exit 1
}

# Match the XDG profile location used by Home Manager and our shells.
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
nix --extra-experimental-features 'nix-command flakes' run "$source_dir#home-manager" -- \
    -b before-home-manager "$action" --flake "$source_dir#$configuration"

if [ "$action" = switch ]; then
    echo "Home Manager applied. Next: sh $source_dir/scripts/bootstrap-host.sh"
fi
