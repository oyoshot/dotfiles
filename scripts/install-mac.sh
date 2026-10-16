#!/bin/sh
set -eu

# These host prerequisites cannot be supplied by standalone Home Manager.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Install Command Line Tools with xcode-select --install, then rerun host setup." >&2
  exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Install Homebrew from https://brew.sh, then rerun host setup." >&2
  exit 1
fi
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONFIG_DIR/homebrew/Brewfile" ] || {
  echo "Apply Home Manager first (Brewfile is missing)." >&2
  exit 1
}

brew update
brew bundle --file "$CONFIG_DIR/homebrew/Brewfile" --quiet
