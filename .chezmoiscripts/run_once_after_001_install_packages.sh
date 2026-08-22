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
        retry_delay=$(( 5 * (2 ** (attempt - 1)) ))
        print -u2 "mise install failed; retrying in ${retry_delay}s (${attempt}/3)"
        sleep "$retry_delay"
    done
fi
