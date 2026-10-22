#!/bin/sh
set -eu
# Initialize and activate the user environment; OS prerequisites are managed separately.
usage='Usage: dotfiles-init [--local DIR] [OUTPUT_DIRECTORY]'
case "${1-}" in
  --help|-h) echo "$usage"; exit 0 ;;
esac
# --local reads committed changes from a clone; otherwise follow the published branch.
dotfiles=github:oyoshot/dotfiles/experiment/nix-cli
if [ "${1-}" = --local ]; then
  [ "$#" -ge 2 ] || { echo "$usage" >&2; exit 2; }
  if [ ! -f "$2/flake.nix" ] || ! git -C "$2" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not a dotfiles clone: $2" >&2
    exit 2
  fi
  dotfiles="git+file://$(CDPATH='' cd -- "$2" && pwd -P)"
  shift 2
fi
[ "$#" -le 1 ] || { echo "$usage" >&2; exit 2; }
case "${1-}" in
  -*) echo "$usage" >&2; exit 2 ;;
esac
destination=${1:-${XDG_CONFIG_HOME:-$HOME/.config}/home-manager}
# Absolute paths remain valid after changing directory for mise below.
case "$destination" in /*) ;; *) destination="$PWD/$destination" ;; esac
wsl=false
if [ -n "${WSL_DISTRO_NAME-}" ] || [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] || [ -d /mnt/wslg ]; then
  wsl=true
fi
# Both omnix and Home Manager invoke Nix themselves.
export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG
}extra-experimental-features = nix-command flakes"
if [ -e "$destination" ] || [ -L "$destination" ]; then
  [ -f "$destination/flake.nix" ] || {
    echo "Existing directory has no flake.nix: $destination" >&2
    exit 1
  }
  printf 'Using existing configuration: %s\n' "$destination"
else
  source_dir=$DOTFILES_TEMPLATE
  system=$DOTFILES_SYSTEM
  params=$(jq -cn --arg username "$(id -un)" --arg home "$HOME" --arg system "$system" --arg wsl "$wsl" --arg dotfiles "$dotfiles" '
    def nixString: split("\\")|join("\\\\")|split("\"")|join("\\\"")|split("${")|join("\\${")|split("\n")|join("\\n")|split("\r")|join("\\r")|split("\t")|join("\\t");
    {username:($username|nixString),home:($home|nixString),system:$system,wsl:$wsl,dotfiles:($dotfiles|nixString)}')
  parent=$(dirname -- "$destination")
  mkdir -p "$parent"
  staging=$(mktemp -d "$parent/.dotfiles-init.XXXXXX")
  trap 'rm -rf -- "$staging"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' HUP TERM
  om init --non-interactive --params "$params" -o "$staging/home" "$source_dir#home"
  nix-instantiate --parse "$staging/home/flake.nix" >/dev/null
  mv -T -n -- "$staging/home" "$destination"
  if [ -d "$staging/home" ]; then
    echo "Destination appeared during initialization; left unchanged" >&2
    exit 1
  fi
  printf 'Created: %s\n' "$destination"
fi
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
home-manager -b before-home-manager switch --flake "$destination#home"

# Do not pick up a mise configuration from the caller's project.
cd "$HOME"
if [ "$DOTFILES_SYSTEM" = x86_64-linux ]; then
  sh "$DOTFILES_TEMPLATE/scripts/with-runtime-build.sh" zsh "$DOTFILES_TEMPLATE/scripts/install-runtimes.zsh"
else
  zsh "$DOTFILES_TEMPLATE/scripts/install-runtimes.zsh"
fi
