#!/bin/zsh

# Zoxide
(( ${+commands[zoxide]} )) && eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Mise
(( ${+commands[mise]} )) && eval "$(mise activate zsh)"

# fzf
(( ${+commands[fzf]} )) && eval "$(fzf --zsh)"

if (( ${+commands[brew]} )); then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  # rip
  export GRAVEYARD="~/.Trash"
fi

# anyframe
autoload -Uz anyframe-init && anyframe-init

autoload -Uz compinit && compinit

run_command() {
    command="$1"
    echo "Running: $command"
    eval "$command" &
    pid=$!
    while ps -p $pid > /dev/null; do
        sleep 1
    done
}

up() {
    run_command "brew upgrade" && run_command "brew upgrade --cask --greedy" & run_command "mise up"
    run_command "mas upgrade"
    run_command "rustup update" && run_command "cargo install-update -a"
}

function j() {
    local root="$(git rev-parse --show-toplevel)" && builtin cd "$root"
}

function jj() {
    local repository=$(ghq list --full-path --vcs git | fzf-tmux -p 90%,90%)
    [ -n "$repository" ] && builtin cd "$repository"
}

function awsc() {
  local src=$(aws-vault list --profiles | fzf-tmux -p 90%,90%)
  [ -n "$src" ] && aws-vault exec -n $src
}

function cdd() {
  local directory=$(
    fd -t d \
    | fzf-tmux -p 90%,90%
  )
  [ -n "$directory" ] && cd $directory
}

## キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

bindkey '^[' _ghq-fzf
function _ghq-fzf() {
  local repository=$(ghq list --full-path --vcs git | fzf-tmux -p 90%,90%)
  if [ -n "$repository" ]; then
    BUFFER="cd \"$repository\""
    zle accept-line
  fi

  zle -R -c
}
zle -N _ghq-fzf

## エイリアス

(( ${+commands[nvim]} )) && alias v='nvim'

if (( ${+commands[eza]} )); then
    alias ls='eza --icons --group-directories-first'
    alias l='ls -l --header --git --group'
    alias la='ls -a'
    alias lt='ls --tree'
    alias lla='ls -la --header --git --group'
fi

(( ${+commands[bat]} )) && alias cat='bat --theme ansi'

alias mkdir='mkdir -p'

alias c='clear'

alias e='exit'

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# C で標準出力をクリップボードにコピーする
# mollifier delta blog : http://mollifier.hatenablog.com/entry/20100317/p1
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    alias -g C='| putclip'
fi

# tar
tgz() {
  env COPYFILE_DISABLE=1 tar zcvf "$1" --exclude=".DS_Store" "${@:2}"
}

# ls color
if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null ; then
  LS_COLORS="${LS_COLORS}:ow=01;34"; export LS_COLORS
  export PATH=$PATH:/mnt/c/windows
  alias II='explorer.exe'
fi

# less
export LESSHISTFILE='-'

# Node.js
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_history"

# npm
export NPM_CONFIG_DIR="$XDG_CONFIG_HOME/npm"
export NPM_DATA_DIR="$XDG_DATA_HOME/npm"
export NPM_CACHE_DIR="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_USERCONFIG="$NPM_CONFIG_DIR/npmrc"

# irb
export IRBRC="$XDG_CONFIG_HOME/irb/irbrc"

# Python
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/startup.py"

# pylint
export PYLINTHOME="$XDG_CACHE_HOME/pylint"

# SQLite3
export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite_history"

# MySQL
export MYSQL_HISTFILE="$XDG_STATE_HOME/mysql_history"

# PostgreSQL
export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"

# ripgrep
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# tealdeer
export TEALDEER_CONFIG_DIR="$XDG_CONFIG_HOME/tealdeer"

# GPG
export GPG_TTY=$TTY
export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
