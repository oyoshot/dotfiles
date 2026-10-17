#!/bin/sh
set -eu
# Generate only; activation and host provisioning are separate operations.
usage='Usage: dotfiles-init [--local DIR] {wsl-linux|linux|darwin} [OUTPUT_DIRECTORY]'
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
case "${1-}" in
  wsl-linux|linux)
    [ "$DOTFILES_SYSTEM" = x86_64-linux ] || { echo "This profile requires x86_64 Linux" >&2; exit 2; }
    wsl=false
    [ "$1" != wsl-linux ] || wsl=true
    ;;
  darwin)
    [ "$DOTFILES_SYSTEM" = aarch64-darwin ] || { echo "This profile requires Apple Silicon macOS" >&2; exit 2; }
    wsl=false
    ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
[ "$#" -le 2 ] || { echo "Too many arguments" >&2; exit 2; }
destination=${2:-${XDG_CONFIG_HOME:-$HOME/.config}/home-manager}
if [ -e "$destination" ] || [ -L "$destination" ]; then
  echo "Existing configuration left unchanged: $destination" >&2
  exit 1
fi
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
# om calls nix itself; a fresh host may not enable flakes in nix.conf yet.
export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG
}extra-experimental-features = nix-command flakes"
om init --non-interactive --params "$params" -o "$staging/home" "$source_dir#home"
nix-instantiate --parse "$staging/home/flake.nix" >/dev/null
mv -T -n -- "$staging/home" "$destination"
if [ -d "$staging/home" ]; then
  echo "Destination appeared during initialization; left unchanged" >&2
  exit 1
fi
printf 'Created: %s\n' "$destination"
