#!/bin/sh
set -eu

if [ -e /dev/dxg ]; then
    # WSLg reads host fonts through /mnt/wslg/distro, without a /nix mount.
    # Resolve the profile first, then use a relative link that works in both roots.
    # Refresh after Home Manager updates; WSLg may need a restart to pick up fonts.
    # Remove this bridge if WSLg gains access to Home Manager's font configuration.
    font_source=$(readlink -e "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/share/fonts/truetype/ipag.ttf")
    font_dir=/usr/local/share/fonts/dotfiles-wslg
    sudo install -d -m 755 "$font_dir"
    font_target=$(realpath --relative-to="$font_dir" "$font_source")
    sudo ln -sfnT "$font_target" "$font_dir/ipag.ttf"

    # Home Manager supplies Fcitx and the WSLg patch through Nix.
    systemctl --user daemon-reload
    systemctl --user restart fcitx5-wslg.service
fi
