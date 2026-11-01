#!/bin/sh
set -eu

# These host prerequisites cannot be supplied by standalone Home Manager.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Install Command Line Tools with xcode-select --install, then rerun host setup." >&2
  exit 1
fi
