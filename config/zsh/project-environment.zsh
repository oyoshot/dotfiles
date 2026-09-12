# Loaded on first use, not while constructing an interactive shell.
_dotfiles_without_fallbacks() {
  local entry
  for entry in "${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}/shims" \
      "$XDG_DATA_HOME/deno/bin" "$XDG_DATA_HOME/gem/bin"; do
    path=( ${path:#$entry} )
  done
  [[ ${CARGO_TARGET_DIR-} != "$XDG_DATA_HOME/cargo/target" ]] || unset CARGO_TARGET_DIR
}

_dotfiles_mise_suspend() {
  if [[ -n ${MISE_SHELL-} && -n $__MISE_BIN ]]; then
    local generated
    generated=$("$__MISE_BIN" deactivate) || return
    eval "$generated"
  fi
  _dotfiles_without_fallbacks
}

_dotfiles_mise_resume() {
  [[ -n $__MISE_BIN ]] || return 0
  local generated saved_handler
  if [[ -z ${MISE_SHELL-} ]] || (( ! $+functions[_dotfiles_mise_command] )); then
    # Preserve the WSL command-not-found handler instead of installing an
    # independent mise activation path that could run inside a Nix shell.
    saved_handler=${functions[command_not_found_handler]-}
    generated=$("$__MISE_BIN" activate zsh --no-hook-env) || return
    eval "$generated"
    if [[ -n $saved_handler ]]; then
      functions[command_not_found_handler]=$saved_handler
    else
      unfunction command_not_found_handler 2>/dev/null || true
    fi
    functions[_dotfiles_mise_command]=$functions[mise]
    mise() {
      (( $+functions[__load_github_token_once] )) && __load_github_token_once
      _dotfiles_mise_command "$@"
    }
  fi
  # Legacy standalone tools remain available only outside a Nix project.
  path+=( $XDG_DATA_HOME/deno/bin(N-/) $XDG_DATA_HOME/gem/bin(N-/) )
  export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$XDG_DATA_HOME/cargo/target}"
  generated=$("$__MISE_BIN" hook-env -s zsh) || return
  eval "$generated"
  path=( ${path:#${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}/shims} )
}

_dotfiles_environment_hook() {
  # A directly entered Nix shell owns its environment until the shell exits.
  [[ -z ${DOTFILES_NIX_SHELL-} ]] || return 0
  [[ -z ${IN_NIX_SHELL-} || -n ${DIRENV_DIR-} ]] || return 0

  # Builtin file checks only. A flake alone is never an opt-in.
  local directory=$PWD envrc=
  while true; do
    if [[ -f $directory/.envrc ]]; then
      envrc=$directory/.envrc
      break
    fi
    [[ $directory != / ]] || break
    directory=${directory:h}
  done
  if [[ -n $__DOTFILES_DIRENV && -n $envrc${DIRENV_DIR-} ]]; then
    _dotfiles_mise_suspend || return
    local generated
    generated=$("$__DOTFILES_DIRENV" export zsh) || return
    eval "$generated"
  fi
  if [[ -z ${IN_NIX_SHELL-} ]]; then
    _dotfiles_mise_resume
  fi
  return 0
}

_dotfiles_nix() {
  case ${1-} in
    develop|shell)
      # Undo mise before Nix captures the environment. The parent stays intact.
      (
        _dotfiles_mise_suspend || return
        export DOTFILES_NIX_SHELL=1
        command nix "$@"
      )
      ;;
    *) command nix "$@" ;;
  esac
}

_dotfiles_environment_init() {
  typeset -g __DOTFILES_DIRENV=
  local directory
  for directory in "$path[@]"; do
    if [[ -x $directory/direnv && ! -d $directory/direnv ]]; then
      __DOTFILES_DIRENV=$directory/direnv
      break
    fi
  done
  # Preserve inherited mise bookkeeping; deactivate needs it to undo the parent.
  _dotfiles_environment_hook
  add-zsh-hook chpwd _dotfiles_environment_hook
  add-zsh-hook precmd _dotfiles_environment_hook
}
