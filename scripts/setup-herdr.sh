#!/bin/sh
set -eu

export PATH="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/bin:$PATH"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export CODEX_HOME="${CODEX_HOME:-$XDG_CONFIG_HOME/codex}"
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$XDG_CONFIG_HOME/claude}"

# Nix builds the binary. Only registration of mutable user settings happens here.
# This plugin's manifest has no runtime events; its functionality is these hooks.
mkdir -p "$CODEX_HOME" "$CLAUDE_CONFIG_DIR"
herdr-plugin-agent-title install-hooks

integration_status="$(herdr integration status)"

for agent in codex claude; do
    if ! printf '%s\n' "$integration_status" |
        grep -Eq "^${agent}: (installed|current) \("; then
        herdr integration install "$agent"
    fi
done
