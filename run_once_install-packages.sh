#!/bin/bash

# Install Rust
if ! type rustup > /dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# Install cargo related tools
if ! type cargo-expand > /dev/null 2>&1; then
  cargo install cargo-expand
fi
if ! type cargo-nextest > /dev/null 2>&1; then
  cargo install cargo-nextest
fi
if ! type cargo-deny > /dev/null 2>&1; then
  cargo install cargo-deny
fi
if ! type cargo-make > /dev/null 2>&1; then
  cargo install cargo-make
fi
if ! type cargo-udeps > /dev/null 2>&1; then
  cargo install cargo-udeps
fi
if ! type cargo-audit > /dev/null 2>&1; then
  cargo install cargo-audit
fi
if ! type cargo-crev > /dev/null 2>&1; then
  cargo install cargo-crev
fi
if ! type cargo-compete > /dev/null 2>&1; then
  cargo install cargo-compete
fi

# Install tools managed by homebrew
{{ if eq .chezmoi.os "darwin" }}
if ! type xcode-select > /dev/null 2>&1; then
  xcode-select --install
fi
brew bundle --global
{{ end }}

# Install mise dependencies
if type mise > /dev/null 2>&1; then
  mise install
fi

exit 0
