#!/bin/zsh

# Deno
_cpu_count() {
  if command -v getconf >/dev/null; then getconf _NPROCESSORS_ONLN
  elif command -v nproc   >/dev/null; then nproc
  elif [[ "$OSTYPE" == darwin* ]];  then sysctl -n hw.ncpu
  else echo 1; fi
}

export DENO_JOBS=$(( $(_cpu_count) + 1 ))

# Go
export GO111MODULE="on"

# less
export LESSHISTFILE='-'

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

#export TF_DATA_DIR="$XDG_DATA_HOME/terraform/$(pwd)"
#export TF_PLUGIN_CACHE_DIR="$XDG_CACHE_HOME/terraform"
#export TF_LOG_PATH="$XDG_DATA_HOME/terraform/terraform.log"

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

function g() {
    local root="$(git rev-parse --show-toplevel)" && builtin cd "$root"
}

function gg() {
    local root
    root=$(ghq root) || return $?
    local r
    r=$(ghq list | fzf --tmux 90% --preview-window="right,40%" --preview="git --git-dir '$root/{}/.git' log --color=always")
    local fzf_status=$?
    if [[ $fzf_status -ne 0 ]]; then
     return $fzf_status
    fi
    if [[ -z "$r" ]]; then
     return 1
    fi
    local repository="$root/$r"
    builtin cd "$repository"
}

function wtx() {
  local target
  target="$(
    git wt |
      tail -n +2 |
      fzf --tmux 90% --ansi --exit-0 --layout=reverse --info=hidden --no-multi \
        --preview-window='right,40%' \
        --bind='tab:down,shift-tab:up,btab:up' \
        --preview='echo {} | awk '\''{print $NF}'\'' | xargs git show --color=always' |
      awk '{print $(NF-1)}'
  )" || return $?
  [[ -n "$target" ]] || return 1
  git wt "$target"
}

function awsc() {
  local src=$(aws-vault list --profiles | fzf --tmux 90%)
  echo "
Vim にすれば...
生産性向上！
健康！
将来安定！
幸福度UP！
                  ⠀⠀⠀⠀⠀⠀⢠⣾⣿⠷⠒⠛⠉⠛⠓⠦⣤⣶⣳⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⠖⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣻⠽⠀⢀⣠⡔⣦⣄⠀⠰⣟⢻⡁⠉⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠸⠉⠙⠲⢷⣄⡈⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⡿⠁⣠⠖⠋⠘⣇⡇⠈⠳⡄⠘⢷⣷⠀⠀⢹⡄⠀⠀⠀⠀⠀⠀⠀
⠨⠷⣶⡦⢄⡈⠑⢦⡈⢧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⡿⢡⡼⣓⠁⠀⠀⢿⣿⠒⠢⢽⡄⠀⠸⣧⠀⠀⢻⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠉⠙⠒⠯⢤⣽⡀⠉⠲⣄⠀⠀⠀⠀⠀⠀⠀⡼⢹⠇⣾⠻⣁⡟⠀⠀⠀⠻⢾⣉⡾⣷⠠⢐⣿⡆⠂⠀⢳⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠑⠦⡀⠑⢄⠀⠀⢀⣀⡼⢁⣾⣿⡏⠀⠀⢠⠤⣤⣀⡀⠀⠉⠀⢸⣼⣿⣿⣷⠸⡀⠈⢧⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣄⠳⣾⣿⣿⣷⣼⡭⣿⣧⡀⠀⡼⠀⠀⢸⠀⠀⠀⢀⣼⣿⣿⠟⢻⡀⣧⠀⠘⣇⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣇⠀⠀⢸⠀⣀⣠⣾⣿⡟⠁⠀⠈⡇⢸⡄⠀⢹⡆⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⡿⠉⣛⣿⣯⠿⣻⡿⠛⢿⣿⠓⠀⠀⠀⣇⠈⣇⠀⠈⣿⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡼⠉⣽⡹⣏⣟⣻⣿⣷⢴⡿⢩⣿⡞⠹⡄⠀⠀⣹⣇⠀⠀⠀⣟⠀⢿⠀⢃⠸⣧⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠃⢰⣯⢳⡝⣦⢻⣿⢏⡾⠁⢸⠀⠷⢶⠿⣿⣿⣿⣿⠀⠀⢀⣏⠰⠌⠀⠸⡐⡽⡄⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡞⠀⣾⢧⡻⣜⡧⠟⠛⣾⠁⢀⡿⠒⠎⢦⢹⣿⣿⣿⣿⣧⠀⢰⡇⠨⢀⡐⠀⡇⣝⣳⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠃⢀⡿⣧⣛⣾⢿⡄⢀⣽⣠⣏⠀⠢⠄⡈⢺⣿⣿⣿⣿⣿⡆⣸⠃⠀⡀⢧⠀⢸⢰⠽⡆
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⢠⠊⣹⢧⢯⡽⣮⢿⣿⣿⣿⣿⣧⣀⣤⣴⣿⣿⣯⣿⢿⣿⣿⡿⠀⠁⡀⢸⠆⢸⣹⢚⣷
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣯⡏⠀⣿⣛⡮⣗⠿⣦⣽⠛⠿⣿⣿⣿⣿⣿⢻⣿⣷⣿⣿⣿⣿⢃⡀⠁⡀⢸⢣⠸⡜⣷⢺
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⠀⢸⢸⡿⡼⣭⡻⣵⡿⣯⣙⢚⣧⣴⠒⣋⣡⣴⣟⠳⠴⢿⣿⣾⠀⠠⠀⡼⢣⢸⡕⣻⣿
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡄⢸⡇⠏⣷⡳⡽⢶⡟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠘⠀⣯⡄⠀⠄⣏⣛⢦⠽⣱⣟
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⡘⣿⣄⢹⣳⡽⠋⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠹⣶⠀⢸⢣⡝⢮⡹⣥⡟
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⣼⡹⢾⠏⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠙⢧⣜⡳⣚⢧⢳⡽⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢿⠂⠀⠀⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⢹⢶⡙⣮⠟⠁⠀
⠀⠀    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠿⢛⡿⠿⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⢸⡧⠟⠁⠀⠀⠀
"
  [ -n "$src" ] && aws-vault exec "$src" "$@"
}

function cdd() {
  local directory=$(
    fd -t d \
    | fzf --tmux 90%
  )
  [ -n "$directory" ] && cd $directory
}

if type yay > /dev/null 2>&1 && type mise > /dev/null 2>&1; then
  function ya() {
    mise deactivate && yay "$@" && eval "$(mise activate zsh)"
  }
fi

## キーバインド

bindkey '^[' _ghq-fzf
function _ghq-fzf() {
  local repository=$(ghq list --full-path --vcs git | fzf --tmux 90%)
  if [ -n "$repository" ]; then
    BUFFER="cd \"$repository\""
    zle accept-line
  fi

  zle -R -c
}
zle -N _ghq-fzf

## エイリアス

alias trash='trash-put'

(( ${+commands[nvim]} )) && alias v='nvim'

if (( ${+commands[eza]} )); then
    alias ls='eza --icons --group-directories-first'
    alias l='ls -l --header --git --group'
    alias la='ls -a'
    alias lt='ls --tree'
    alias lla='ls -la --header --git --group'
fi

(( ${+commands[bat]} )) && alias b='bat --theme ansi'

(( ${+commands[memo]} )) && alias m='memo'

alias mkdir='mkdir -p'

alias c='clear'

alias e='exit'

if type tmux > /dev/null 2>&1; then
  alias t='tmux'
  alias ta='tmux a'
  alias tn='tmux new -A -s $(whoami)'
fi

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

if (( ${+commands[brew]} )); then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  # rip
  export GRAVEYARD="~/.Trash"
fi

# Zoxide
(( ${+commands[zoxide]} )) && eval "$(zoxide init zsh)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
(( ${+commands[fzf]} )) && source <(fzf --zsh)

# anyframe
autoload -Uz anyframe-init && anyframe-init

autoload -Uz compinit && compinit

if (( ${+TMUX} && $+commands[tmux] )); then
  VISUAL='tmux display-popup -E -h 80% -w 90% -d '#{pane_current_path}' nvim'
else
  VISUAL='nvim'
fi
export VISUAL FCEDIT=$VISUAL

autoload -Uz edit-command-line
zle      -N  edit-command-line

bindkey -M vicmd 'jj' edit-command-line
bindkey -M viins 'jj' edit-command-line
