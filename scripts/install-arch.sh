#!/bin/sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

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
