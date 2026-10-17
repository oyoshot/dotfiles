#!/usr/bin/env bash
# Cache only custom runtime closures; official packages use cache.nixos.org.
set -euo pipefail
cache_dir=/tmp/dotfiles-nix-cache
mkdir -p "$cache_dir"
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
export NIX_CONFIG='experimental-features = nix-command flakes'
# Keep the command array nonempty for macOS's system Bash with nounset.
executor=(env)
if [[ $(uname -s) == Linux ]]; then
    executor=(sudo -Hu builder env
        PATH=/home/builder/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin
        "NIX_CONFIG=$NIX_CONFIG")
    importer=("${executor[@]}" nix-store)
else
    # The daemon only permits a trusted user to import unsigned local builds.
    importer=(sudo /nix/var/nix/profiles/default/bin/nix-store)
fi
if [[ -f "$cache_dir/closure.nar" ]]; then
    "${importer[@]}" --import < "$cache_dir/closure.nar"
fi
outputs=$("${executor[@]}" nix build --no-link --print-out-paths \
    .#zsh-autocomplete-rs .#herdr-plugin-agent-title)
# Store paths contain no whitespace. Export dependencies as well as executables.
# shellcheck disable=SC2086
closure=$("${executor[@]}" nix-store --query --requisites $outputs)
# shellcheck disable=SC2086
"${executor[@]}" nix-store --export $closure > "$cache_dir/closure.nar.new"
mv "$cache_dir/closure.nar.new" "$cache_dir/closure.nar"
