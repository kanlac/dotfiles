#!/bin/sh
# Claude Code status line — context, model, session, tokens, cost

input=$(cat)

# ANSI colors
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
DIM='\033[2m'
RESET='\033[0m'

# Model display name (shorten for conciseness)
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')

# Session ID (first 4 chars)
session_id=$(echo "$input" | jq -r '.session_id // ""' | cut -c1-4)

# Context usage percentage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  used_pct_int=$(printf "%.0f" "$used_pct")
  ctx_str="${used_pct_int}%"
else
  ctx_str="n/a"
fi

# Token counts (cumulative session totals)
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Format token counts with k suffix
fmt_tokens() {
  val=$1
  if [ "$val" -ge 1000 ] 2>/dev/null; then
    printf "%.1fk" "$(echo "$val / 1000" | bc -l 2>/dev/null || echo 0)"
  else
    echo "$val"
  fi
}
in_fmt=$(fmt_tokens "$total_in")
out_fmt=$(fmt_tokens "$total_out")

# Approximate cost: $3/M input, $15/M output (Sonnet pricing)
cost=$(echo "$total_in $total_out" | awk '{printf "%.3f", ($1 * 3 + $2 * 15) / 1000000}')

# Rate limit usage (Claude.ai subscription; only present after first API response)
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate_str=""
if [ -n "$five_pct" ]; then
  rate_str="${rate_str}5h:$(printf '%.0f' "$five_pct")%"
fi
if [ -n "$week_pct" ]; then
  [ -n "$rate_str" ] && rate_str="${rate_str} "
  rate_str="${rate_str}7d:$(printf '%.0f' "$week_pct")%"
fi

# Build output — append rate limits only when data is available
base="${CYAN}ctx:${used_pct_int:-?}%${RESET} ${DIM}|${RESET} ${MAGENTA}${model}${RESET} ${DIM}|${RESET} ${BLUE}session:${session_id}${RESET} ${DIM}|${RESET} ${GREEN}in:${in_fmt} out:${out_fmt}${RESET} ${DIM}|${RESET} ${YELLOW}\$${cost}${RESET}"
if [ -n "$rate_str" ]; then
  printf '%b' "${base} ${DIM}|${RESET} ${YELLOW}${rate_str}${RESET}"
else
  printf '%b' "${base}"
fi
