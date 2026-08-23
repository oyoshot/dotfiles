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
    # mise's HTTP retry covers receiving a response, but not a timeout while
    # reading its body. Retry the whole install for transient crates.io index
    # body timeouts. Remove this once mise retries response-body failures.
    max_attempts=3
    attempt=1
    retry_delay=30

    while ! mise install -y -v; do
        if (( attempt >= max_attempts )); then
            print -u2 "mise install failed after ${attempt} attempts"
            exit 1
        fi

        print -u2 "mise install attempt ${attempt} failed; retrying in ${retry_delay}s"
        sleep "$retry_delay"
        (( attempt += 1 ))
        (( retry_delay *= 2 ))
    done
fi
