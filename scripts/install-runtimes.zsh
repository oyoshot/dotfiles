#!/bin/zsh
set -euo pipefail

if [[ -z ${IN_NIX_SHELL-} ]]; then
    export PATH="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/bin:$PATH"
fi

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

    # mise 2026.9.18 still treats the llvm-tools-preview alias as missing:
    # rustup reports the installed component as llvm-tools-<host>.
    # Remove this step once the seed and existing mutable Rust configurations
    # declare rust-analyzer,llvm-tools,rust-src (preserving selected versions).
    # Until then, let rustup resolve aliases and provision the components.
    mise exec -- rustup component add rust-analyzer llvm-tools-preview rust-src
fi
