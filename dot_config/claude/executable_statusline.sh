#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.id')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Format duration as Xm Ys
DURATION_S=$((DURATION_MS / 1000))
MINUTES=$((DURATION_S / 60))
SECONDS=$((DURATION_S % 60))
if [ "$MINUTES" -gt 0 ]; then
    TIME="${MINUTES}m${SECONDS}s"
else
    TIME="${SECONDS}s"
fi

# Format cost
COST_FMT=$(printf "$%.2f" "$COST")

echo "[$MODEL] Context: ${PCT}% | ${COST_FMT} | ${TIME}"
