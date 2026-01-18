#!/usr/bin/env zsh

# Usage:
#   lc                      # default: provider=claude, lang=en
#   lc codex                # specify provider
#   lc claude ja            # provider + lang
#   lc ja                   # lang only (provider via env/default)
#
# Environment variables:
#   LC_PROVIDER=codex|claude
#   LC_LANG=en|ja|<lang>     # any language name or instruction
#   LC_DRY_RUN=1             # show generated message only
#
# Examples:
#   export LC_PROVIDER=codex
#   export LC_LANG=ja
#   lc
#   lc claude en
#   LC_DRY_RUN=1 lc codex ja

_lc_prompt() {
    local lang="${1:-en}"
    local lang_name="$lang"

    case "$lang" in
    ja)
        lang_name="Japanese"
        ;;
    en)
        lang_name="English"
        ;;
    esac

    cat <<EOF
You are generating a Git commit message that MUST follow the Conventional Commits specification.

IMPORTANT: Do NOT use any other language. Output ${lang_name} only.

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

_lc_codex() {
    local tmp="$1"
    local lang="$2"

    {
        _lc_prompt "$lang"
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

_lc_claude() {
    local tmp="$1"
    local lang="$2"

    {
        _lc_prompt "$lang"
        echo
        git diff --staged
    } | claude -p \
        --output-format text \
        >"$tmp"
}

lc() {
    # Exit if there are no staged changes.
    if git diff --staged --quiet; then
        echo "No staged changes."
        return 1
    fi

    # Parse args:
    #  - provider: codex|claude
    #  - lang: en|ja or any custom language name

    local a1="${1:-}"
    local a2="${2:-}"

    local provider=""
    local lang=""

    case "$a1" in
    codex | claude) provider="$a1" ;;
    "") : ;;
    *) lang="$a1" ;;
    esac

    case "$a2" in
    "") : ;;
    codex | claude)
        echo "Unknown arg: $a2 (provider must be first)"
        return 2
        ;;
    *)
        if [ -z "$provider" ]; then
            echo "Too many args. Usage: lc [codex|claude] [lang]"
            return 2
        fi
        lang="$a2"
        ;;
    esac

    provider="${provider:-${LC_PROVIDER:-claude}}"
    lang="${lang:-${LC_LANG:-en}}"

    local tmp
    tmp="$(mktemp)"

    case "$provider" in
    codex) _lc_codex "$tmp" "$lang" || true ;;
    claude) _lc_claude "$tmp" "$lang" || true ;;
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

    if [ -n "${LC_DRY_RUN:-}" ]; then
        cat "$tmp"
        rm -f "$tmp"
        return 0
    fi

    git commit -F "$tmp"
    rm -f "$tmp"
}
