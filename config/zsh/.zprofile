if [[ $OSTYPE == darwin* && -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=/opt/homebrew/Cellar
  export HOMEBREW_REPOSITORY=/opt/homebrew
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
  [[ -z ${MANPATH-} ]] || export MANPATH=":${MANPATH#:}"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

  export HOMEBREW_BUNDLE_FILE_GLOBAL="${XDG_CONFIG_HOME}/homebrew/Brewfile"
  export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/homebrew/Brewfile"
fi

[ -d "$NOTES_DIR" ] || mkdir -p "$NOTES_DIR"/{assets,images,pdf,resume,logs}
