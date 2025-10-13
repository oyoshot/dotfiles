#!/usr/bin/env bash
set -euo pipefail

export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export CARGO_TARGET_DIR="$CARGO_HOME/target"

if [[ ! -f "$CARGO_HOME/env" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
        sh -s -- -y --no-modify-path
fi

source "$CARGO_HOME/env"

rustup default stable &&
    rustup component add rust-analyzer &&
    rustup component add llvm-tools-preview

# Install Mise dependency
if type mise >/dev/null 2>&1; then
    mise install -y -v
fi
