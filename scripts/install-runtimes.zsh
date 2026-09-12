#!/bin/zsh
set -euo pipefail

export PATH="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/bin:$PATH"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# Install project-scoped runtimes and development tools.
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

    # mise 2026.8.6 repeatedly treats an existing Rust toolchain as missing
    # when components are declared as tool options. Reconcile them through the
    # rustup installed by mise until the fixed mise release reaches nixpkgs.
    mise exec -- rustup component add rust-analyzer llvm-tools-preview rust-src
fi
