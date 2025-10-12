#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"
HOME_DIR="${HOME}"

LOG="$(nvim --headless '+lua print(vim.lsp.log.get_filename())' +q 2>/dev/null | tail -n1 || true)"
: "${LOG:=${HOME_DIR}/.local/state/nvim/lsp.log}"

mkdir -p "${HOME_DIR}/.config/logrotate.d" "${HOME_DIR}/.cache"

cat >"${HOME_DIR}/.config/logrotate.d/nvim" <<EOF
${LOG} {
  size 16M
  rotate 7
  compress
  copytruncate
  missingok
  notifempty
  dateext
}
EOF

if [ "${OS}" = "Linux" ]; then
    systemctl --user daemon-reload || true
    systemctl --user enable --now logrotate-nvim.timer || true
    echo "[ok] systemd user timer enabled (logrotate-nvim.timer)"
elif [ "${OS}" = "Darwin" ]; then
    PLIST="${HOME_DIR}/Library/LaunchAgents/com.local.nvim-lsp-logrotate.plist"
    launchctl unload "$PLIST" >/dev/null 2>&1 || true
    launchctl load "$PLIST"
    echo "[ok] launchd job loaded (com.local.nvim-lsp-logrotate)"
fi

echo "[ok] logrotate.d entry written for: ${LOG}"
