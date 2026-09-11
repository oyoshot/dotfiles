#!/bin/sh
set -eu

profile="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager/home-path"
export PATH="$profile/bin:$PATH"
for tool in rg fd jq gh nvim herdr herdr-plugin-agent-title codex claude pyright stylua zsh-autocomplete-rs; do
    actual=$(command -v "$tool")
    [ "$actual" = "$profile/bin/$tool" ] || {
        echo "Unexpected $tool path: $actual" >&2
        exit 1
    }
done
rg --version
fd --version
jq --version
herdr --version
pyright --version
stylua --version
zacrs_init="${TMPDIR:-/tmp}/zacrs-init.$$"
trap 'rm -f "$zacrs_init"' EXIT HUP INT TERM
zsh-autocomplete-rs init zsh > "$zacrs_init"
zsh -n "$zacrs_init"
NVIM_LOG_FILE="${TMPDIR:-/tmp}/dotfiles-nvim-check.log" nvim --headless -u NONE -i NONE \
    '+lua assert(vim.fn.executable("pyright") == 1)' +qa

# Interactive activation used to prepend stale mise shims over Nix tools.
zsh -ic '
    __mise_activate_once
    for pass in 1 2; do
        for tool in rg nvim herdr pyright; do
            [[ $(command -v "$tool") == "$XDG_STATE_HOME/nix/profiles/home-manager/home-path/bin/$tool" ]] || exit 1
        done
        _mise_hook
    done
'

# A fresh runner must receive dotfiles and external sources from Home Manager.
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
export CODEX_HOME="$config_dir/codex"
export CLAUDE_CONFIG_DIR="$config_dir/claude"
integration_status=$(herdr integration status)
for agent in codex claude; do
    printf '%s\n' "$integration_status" | grep -Eq "^${agent}: (installed|current) \\("
done
for settings in "$CODEX_HOME/hooks.json" "$CLAUDE_CONFIG_DIR/settings.json"; do
    jq -e '[.hooks.SessionStart[], .hooks.UserPromptSubmit[], .hooks.Stop[] |
        .hooks[] | select(.command | contains("herdr-plugin-agent-title-managed"))] | length == 3' "$settings"
done
for file in \
    zsh/.zshrc nvim/init.lua git/config textlint/textlintrc \
    zsh/plugins/zsh-defer/zsh-defer.plugin.zsh \
    zsh/plugins/autosuggestions/zsh-autosuggestions.zsh \
    zsh/plugins/syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
    zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
    zsh/fpath/aws_zsh_completer.sh zsh/plugins/ni.zsh \
    tmux/plugins/tpm/tpm prh-rules/media/WEB+DB_PRESS.yml; do
    [ -r "$config_dir/$file" ] || { echo "Missing Home Manager file: $file" >&2; exit 1; }
done
[ -x "$config_dir/herdr/scripts/herdr-open" ]
[ -x "$config_dir/claude/statusline.sh" ]
