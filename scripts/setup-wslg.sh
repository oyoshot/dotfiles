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

    # WSLg does not scan ~/.local/share/applications for its Windows Start-menu
    # integration.  Its /usr/local entry is scanned after /usr, so this desktop
    # file overrides the package launcher without modifying a pacman-owned file.
    ghostty_desktop="$HOME/.local/share/applications/com.mitchellh.ghostty.desktop"
    sudo install -Dm0644 "$ghostty_desktop" \
        /usr/local/share/applications/com.mitchellh.ghostty.desktop
fi
