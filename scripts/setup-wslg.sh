#!/bin/sh
set -eu

if [ -e /dev/dxg ]; then
    source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
    workaround="$source_dir/.workarounds/REMOVE_WHEN_WSLG_1495_IS_FIXED/fcitx5-wslg-workaround"
    fcitx5_version=$(pacman -Q fcitx5 2>/dev/null | awk '{ print $2 }')
    case "$fcitx5_version" in
        5.1.21-1|5.1.21-1.1)
            sh "$workaround" install
            ;;
        *)
            printf 'warning: skipping WSLg #1495 workaround for unsupported fcitx5 version %s\n' \
                "${fcitx5_version:-not-installed}" >&2
            ;;
    esac

    systemctl --user daemon-reload
    systemctl --user restart fcitx5-wslg.service
fi
