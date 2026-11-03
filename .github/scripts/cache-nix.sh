#!/usr/bin/env bash
# Cache runtime closures built locally in CI; official binaries use cache.nixos.org.
set -euo pipefail
cache_dir=/tmp/dotfiles-nix-cache
mkdir -p "$cache_dir"
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
export NIX_CONFIG='experimental-features = nix-command flakes'
# Keep the command array nonempty for macOS's system Bash with nounset.
executor=(env)
targets=(.#zsh-autocomplete-rs .#herdr-plugin-agent-title)
if [[ $(uname -s) == Linux ]]; then
    executor=(sudo -Hu builder env
        PATH=/home/builder/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin
        "NIX_CONFIG=$NIX_CONFIG")
    importer=("${executor[@]}" nix-store)
else
    # The daemon only permits a trusted user to import unsigned local builds.
    importer=(sudo /nix/var/nix/profiles/default/bin/nix-store)
    # The Darwin WezTerm package is built from source, including its tests.
    targets+=(.#homeConfigurations.ci-darwin.pkgs.wezterm)
fi
if [[ -f "$cache_dir/closure.nar" ]]; then
    "${importer[@]}" --import < "$cache_dir/closure.nar"
fi
outputs=$("${executor[@]}" nix build --no-link --print-out-paths --print-build-logs \
    "${targets[@]}")
# Store paths contain no whitespace. Export dependencies as well as executables.
# shellcheck disable=SC2086
closure=$("${executor[@]}" nix-store --query --requisites $outputs)
# shellcheck disable=SC2086
"${executor[@]}" nix-store --export $closure > "$cache_dir/closure.nar.new"
mv "$cache_dir/closure.nar.new" "$cache_dir/closure.nar"
