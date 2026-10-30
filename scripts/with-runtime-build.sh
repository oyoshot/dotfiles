#!/bin/sh
# Run mise installers with persistent roots for their native build environments.
set -eu
source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
build_profiles="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
build_roots="${XDG_STATE_HOME:-$HOME/.local/state}/nix/runtime-build-roots"
mkdir -p "$build_profiles" "$build_roots"

retain_environment() {
    environment=$(readlink -f "$1")
    nix-store --realise "$environment" \
        --add-root "$build_roots/${environment##*/}" --indirect >/dev/null
}

# Cargo tools already at the requested version are not rebuilt by mise up.
# Preserve existing generations before advancing the profile, including builds
# from before this retention scheme was introduced.
for profile in "$build_profiles/runtime-build" "$build_profiles"/runtime-build-*-link; do
    [ -e "$profile" ] || continue
    retain_environment "$profile"
done

# Root the new environment before running an installer, even if it later fails.
nix print-dev-env --no-update-lock-file --profile "$build_profiles/runtime-build" \
    "$source_dir#native" >/dev/null
retain_environment "$build_profiles/runtime-build"

# These roots are independent of profile generations. Remove them only after
# all tools built with those environments have been removed or rebuilt.
exec nix develop "$environment" --command "$@"
