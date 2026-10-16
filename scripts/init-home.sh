#!/bin/sh
set -eu
# Generate only; activation and host provisioning are separate operations.
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
  *) echo "Usage: dotfiles-init {wsl-linux|linux|darwin} [OUTPUT_DIRECTORY]" >&2; exit 2 ;;
esac
[ "$#" -le 2 ] || { echo "Too many arguments" >&2; exit 2; }
destination=${2:-${XDG_CONFIG_HOME:-$HOME/.config}/home-manager}
if [ -e "$destination" ] || [ -L "$destination" ]; then
  echo "Existing configuration left unchanged: $destination" >&2
  exit 1
fi
source_dir=$DOTFILES_TEMPLATE
system=$DOTFILES_SYSTEM
params=$(jq -cn --arg username "$(id -un)" --arg home "$HOME" --arg system "$system" --arg wsl "$wsl" '
  def nixString: split("\\")|join("\\\\")|split("\"")|join("\\\"")|split("${")|join("\\${")|split("\n")|join("\\n")|split("\r")|join("\\r")|split("\t")|join("\\t");
  {username:($username|nixString),home:($home|nixString),system:$system,wsl:$wsl}')
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
