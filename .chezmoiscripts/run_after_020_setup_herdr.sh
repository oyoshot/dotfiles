#!/bin/sh
set -eu

if ! command -v herdr >/dev/null 2>&1; then
    exit 0
fi

# Herdr plugin manifests execute binaries below their own target directory.
# Do not let the user's shared Cargo target redirect plugin build artifacts.
unset CARGO_TARGET_DIR

if ! herdr plugin list | grep -Fq 'herdr-plugin-renamer'; then
    herdr plugin install wyattjoh/herdr-plugin-renamer --yes
fi

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"
plugin_root=""

if command -v jq >/dev/null 2>&1 && [ -f "$config_dir/plugins.json" ]; then
    plugin_root="$(
        jq -r '.[] | select(.plugin_id == "herdr-plugin-renamer") | .plugin_root' \
            "$config_dir/plugins.json" | head -n 1
    )"
fi

if [ -n "$plugin_root" ] &&
    [ ! -x "$plugin_root/target/release/herdr-plugin-renamer" ]; then
    cargo build --release --manifest-path "$plugin_root/Cargo.toml"

    if [ "$(uname -s)" = Darwin ] && command -v swift >/dev/null 2>&1; then
        swift build -c release --package-path "$plugin_root/naming-helper"
    fi
fi

integration_status="$(herdr integration status)"

for agent in codex claude; do
    if ! printf '%s\n' "$integration_status" |
        grep -Eq "^${agent}: (installed|current) \("; then
        herdr integration install "$agent"
    fi
done
