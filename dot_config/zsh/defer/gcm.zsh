#!/usr/bin/env zsh

# 使い方:
#
#   gcm                      # デフォルト: provider=codex, lang=en
#   gcm codex                # provider 指定
#   gcm claude ja            # provider + lang 指定
#   gcm ja                   # lang だけ指定（provider は env/既定）
#
# 環境変数:
#   GCM_PROVIDER=codex|claude
#   GCM_LANG=en|ja
#   GCM_DRY_RUN=1            # 生成だけ表示
#
# 例:
#   export GCM_PROVIDER=codex
#   export GCM_LANG=ja
#   gcm
#
#   gcm claude en
#   GCM_DRY_RUN=1 gcm codex ja

_gcm_prompt() {
    local lang="${1:-en}"
    local lang_name="English"
    local extra=""

    case "$lang" in
    ja)
        lang_name="Japanese"
        extra=$'IMPORTANT: Do NOT use English anywhere. Output Japanese only.\n'
        ;;
    esac

    cat <<EOF
You are generating a Git commit message that MUST follow the Conventional Commits specification.
${extra}

Rules:
- Output ONLY the raw commit message. No markdown, no code blocks, no explanations.
- First line MUST be exactly: <type>(<optional-scope>): <subject>
  - <type> must be one of: feat, fix, docs, refactor, test, chore, ci, build, perf, style, revert
  - scope is optional; if you can infer it from the diff paths, include it (e.g. docs(readme): ...).
- Subject and body MUST be written in ${lang_name}.
- Subject: concise, imperative-ish, and preferably within ~72 chars.
- If a body is needed, add a blank line then bullet points.
- If there is a breaking change, use "!" after type/scope and mention it in the body.

Now generate the commit message for the following staged diff.
EOF
}

_gcm_codex() {
    local tmp="$1"
    local lang="$2"

    {
        _gcm_prompt "$lang"
        echo
        git diff --staged
    } | codex exec \
        --sandbox read-only \
        --color never \
        -c 'approval_policy="never"' \
        -o "$tmp" \
        - \
        >/dev/null 2>&1
}

_gcm_claude() {
    local tmp="$1"
    local lang="$2"

    {
        _gcm_prompt "$lang"
        echo
        git diff --staged
    } | claude -p \
        --output-format text \
        >"$tmp"
}

gcm() {
    # staged 差分が無いなら終了
    if git diff --staged --quiet; then
        echo "No staged changes."
        return 1
    fi

    # 引数の解釈:
    #  - provider: codex|claude
    #  - lang: ja|en

    local a1="${1:-}"
    local a2="${2:-}"

    local provider=""
    local lang=""

    case "$a1" in
    codex | claude) provider="$a1" ;;
    ja | en) lang="$a1" ;;
    "") : ;;
    *)
        echo "Unknown arg: $a1 (use: codex|claude|ja|en)"
        return 2
        ;;
    esac

    case "$a2" in
    ja | en) lang="$a2" ;;
    "") : ;;
    *)
        echo "Unknown lang: $a2 (use: ja|en)"
        return 2
        ;;
    esac

    provider="${provider:-${GCM_PROVIDER:-claude}}"
    lang="${lang:-${GCM_LANG:-en}}"

    local tmp
    tmp="$(mktemp)"

    case "$provider" in
    codex) _gcm_codex "$tmp" "$lang" || true ;;
    claude) _gcm_claude "$tmp" "$lang" || true ;;
    *)
        echo "Unknown provider: $provider (use: codex|claude)"
        rm -f "$tmp"
        return 2
        ;;
    esac

    if [ ! -s "$tmp" ]; then
        echo "No commit message generated."
        rm -f "$tmp"
        return 1
    fi

    if ! head -n 1 "$tmp" | grep -Eq '^(feat|fix|docs|refactor|test|chore|ci|build|perf|style|revert)(\([^)]+\))?!?: .+'; then
        echo "Generated message does not look like Conventional Commits:"
        head -n 5 "$tmp"
        rm -f "$tmp"
        return 1
    fi

    if [ -n "${GCM_DRY_RUN:-}" ]; then
        cat "$tmp"
        rm -f "$tmp"
        return 0
    fi

    git commit -F "$tmp"
    rm -f "$tmp"
}
