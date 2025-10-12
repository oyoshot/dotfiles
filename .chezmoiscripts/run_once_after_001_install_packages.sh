#!/usr/bin/env zsh
set -euo pipefail

if [[ ! -f "$CARGO_HOME/env" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
        sh -s -- -y --no-modify-path
fi

rustup default stable &&
    rustup component add rust-analyzer &&
    rustup component add llvm-tools-preview

# Install Mise dependency
if type mise >/dev/null 2>&1; then
    mise install -y -v
fi
