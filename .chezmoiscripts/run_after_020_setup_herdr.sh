#!/bin/sh
set -eu

if ! command -v herdr >/dev/null 2>&1; then
    exit 0
fi

# Herdr plugin manifests build below their own checkout. Do not redirect those
# artifacts into the shared Cargo target directory.
unset CARGO_TARGET_DIR

plugin_list="$(herdr plugin list)"
title_plugin="herdr-plugin-agent-title"

if ! printf '%s\n' "$plugin_list" | grep -Fq "$title_plugin"; then
    herdr plugin install oyoshot/herdr-plugin-agent-title --yes
fi

integration_status="$(herdr integration status)"

for agent in codex claude; do
    if ! printf '%s\n' "$integration_status" |
        grep -Eq "^${agent}: (installed|current) \("; then
        herdr integration install "$agent"
    fi
done
