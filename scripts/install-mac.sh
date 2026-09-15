#!/bin/sh
set -eu

# Install Homebrew formula
if ! type xcode-select > /dev/null 2>&1; then
  xcode-select --install
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

brew update
brew bundle --file "$CONFIG_DIR/homebrew/Brewfile" --quiet
