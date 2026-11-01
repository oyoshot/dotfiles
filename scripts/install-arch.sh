#!/bin/sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

# Install packages on Arch
sudo pacman -Syu --noconfirm git binutils fakeroot make gcc base base-devel
if ! type yay > /dev/null 2>&1; then
    build_dir=$(mktemp -d)
    trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
    git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
    (cd "$build_dir/yay" && makepkg -si --noconfirm)
fi

sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$CONFIG_DIR/yay/extra-packages" \
    | xargs -r yay -S --needed --noconfirm --batchinstall --answerclean None --answerdiff None --answeredit None --removemake

# Keep mirror selection and its weekly schedule reproducible on new hosts.
sudo install -Dm644 "$source_dir/config/reflector/reflector.conf" /etc/xdg/reflector/reflector.conf
sudo systemctl enable reflector.timer
# Provisioning containers do not run systemd; enable the timer for their next boot.
if [ -d /run/systemd/system ]; then
    sudo systemctl start reflector.timer
fi
