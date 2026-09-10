#!/usr/bin/env bash
set -euo pipefail

LOG="$(nvim --headless '+lua print(vim.lsp.log.get_filename())' +q 2>/dev/null | tail -n1 || true)"
: "${LOG:=${HOME}/.local/state/nvim/lsp.log}"
MAX_MB="${MAX_MB:-16}"

[ -f "$LOG" ] || exit 0

if stat --version >/dev/null 2>&1; then
    SIZE="$(stat -c%s "$LOG")"
else
    SIZE="$(stat -f%z "$LOG")"
fi

if [ "${SIZE}" -ge $((MAX_MB * 1024 * 1024)) ]; then
    TS="$(date -u +%Y%m%d-%H%M%S)"
    ROT="${LOG}.${TS}"
    cp -- "$LOG" "$ROT" 2>/dev/null || /bin/cp "$LOG" "$ROT"
    : >"$LOG" # truncate
    command -v gzip >/dev/null && gzip -f "$ROT" || true
fi
