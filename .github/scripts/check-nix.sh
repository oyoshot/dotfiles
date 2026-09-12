#!/bin/sh
set -eu

profile="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile"
echo "Checking XDG Home Manager profile: $profile"
[ -d "$profile/bin" ] || { echo "Missing XDG Home Manager profile: $profile" >&2; exit 1; }
# Check the actual generation location, not just an alias to ~/.nix-profile.
case "$(readlink "$profile")" in
    "${profile%/profile}/profiles/profile"|profiles/profile) ;;
    *) echo "Profile is not backed by XDG generations: $profile" >&2; exit 1 ;;
esac
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
echo 'Checking zacrs init syntax'
zsh -n "$zacrs_init"
echo 'Checking Neovim and pyright'
NVIM_LOG_FILE="${TMPDIR:-/tmp}/dotfiles-nvim-check.log" nvim --headless -u NONE -i NONE \
    '+lua assert(vim.fn.executable("pyright") == 1)' +qa

# Interactive activation used to prepend stale mise shims over Nix tools.
echo 'Checking interactive Zsh PATH after mise activation'
zsh -ic '
    __mise_activate_once
    for pass in 1 2; do
        for tool in rg nvim herdr pyright; do
            actual=$(command -v "$tool")
            expected="$XDG_STATE_HOME/nix/profile/bin/$tool"
            # The HM home-path and user profile can point at the same binary.
            if [[ ! $actual -ef $expected ]]; then
                print -u2 -r -- "Unexpected $tool path on pass $pass: $actual (expected $expected)"
                exit 1
            fi
        done
        _dotfiles_environment_hook
    done
    exit 0
'

# A fresh runner must receive dotfiles and external sources from Home Manager.
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
export CODEX_HOME="$config_dir/codex"
export CLAUDE_CONFIG_DIR="$config_dir/claude"
integration_status=$(herdr integration status)
echo 'Checking herdr integrations'
for agent in codex claude; do
    printf '%s\n' "$integration_status" | grep -Eq "^${agent}: (installed|current) \\(" || {
        printf 'Missing %s integration:\n%s\n' "$agent" "$integration_status" >&2
        exit 1
    }
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
