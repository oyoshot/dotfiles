#!/bin/bash
input=$(cat)

# jq呼び出しを1回に最適化
read -r MODEL PCT COST DURATION_MS INPUT_TOKENS OUTPUT_TOKENS <<< $(echo "$input" | jq -r '[.model.id, (.context_window.used_percentage // 0 | floor), (.cost.total_cost_usd // 0), (.cost.total_duration_ms // 0), (.context_window.total_input_tokens // 0), (.context_window.total_output_tokens // 0)] | @tsv')

# Format duration as Xm Ys
DURATION_S=$((DURATION_MS / 1000))
MINUTES=$((DURATION_S / 60))
SECONDS=$((DURATION_S % 60))
if [ "$MINUTES" -gt 0 ]; then
    TIME="${MINUTES}m${SECONDS}s"
else
    TIME="${SECONDS}s"
fi

# Format cost (printfバグ修正: $を外に出す)
COST_FMT=$(printf "%.2f" "$COST")

# コンテキスト使用率の警告表示
if [ "$PCT" -ge 80 ]; then
    CTX="[!] ${PCT}%"
else
    CTX="${PCT}%"
fi

# トークン数をk単位でフォーマット
INPUT_K=$(awk "BEGIN {printf \"%.1f\", $INPUT_TOKENS / 1000}")
OUTPUT_K=$(awk "BEGIN {printf \"%.1f\", $OUTPUT_TOKENS / 1000}")

echo "[$MODEL] Context: ${CTX} | ${INPUT_K}k/${OUTPUT_K}k tokens | \$${COST_FMT} | ${TIME}"
