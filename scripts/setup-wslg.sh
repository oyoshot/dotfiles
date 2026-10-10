#!/bin/sh
set -eu

if [ -e /dev/dxg ]; then
    # Home Manager supplies Fcitx and the WSLg patch through Nix.
    systemctl --user daemon-reload
    systemctl --user restart fcitx5-wslg.service
fi
