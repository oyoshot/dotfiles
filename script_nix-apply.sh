#!/bin/sh
# Build first, then switch a dedicated, generation-based profile.
set -eu

source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
profile="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/dotfiles"
for nix_bin in "$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin; do
    if [ -x "$nix_bin/nix" ]; then
        PATH="$nix_bin:$PATH"
        break
    fi
done
export PATH
if ! command -v nix >/dev/null 2>&1; then
    echo "Nix is required. Install Nix first; see $source_dir/NIX.md." >&2
    exit 1
fi

mkdir -p "$(dirname "$profile")"
pending=$(mktemp -d "$(dirname "$profile")/.dotfiles-build.XXXXXX")
trap 'rm -f "$pending/result"; rmdir "$pending"' EXIT HUP INT TERM
nix --extra-experimental-features 'nix-command flakes' build \
    --no-update-lock-file --out-link "$pending/result" "$source_dir#default"
nix-env --profile "$profile" --set "$pending/result"
echo "CLI profile ready: $profile"
