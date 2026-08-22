#!/bin/zsh
set -euo pipefail

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
    for attempt in {1..3}; do
        if mise install -y -v; then
            break
        fi
        (( attempt < 3 )) || exit 1
        sleep $(( attempt * 5 ))
    done
fi
