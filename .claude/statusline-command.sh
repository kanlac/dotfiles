#!/bin/sh
# Claude Code status line — git branch, context, model, session, rate limits

input=$(cat)

# ANSI colors
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
DIM='\033[2m'
RESET='\033[0m'

# Git branch
git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

# Model display name (shorten for conciseness)
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')

# Session ID (first 4 chars)
session_id=$(echo "$input" | jq -r '.session_id // ""' | cut -c1-4)

# Context usage percentage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  used_pct_int=$(printf "%.0f" "$used_pct")
else
  used_pct_int="?"
fi

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

# Build output
base=""
if [ -n "$git_branch" ]; then
  base="${GREEN}${git_branch}${RESET} ${DIM}|${RESET} "
fi
base="${base}${CYAN}ctx:${used_pct_int}%${RESET} ${DIM}|${RESET} ${MAGENTA}${model}${RESET} ${DIM}|${RESET} ${BLUE}session:${session_id}${RESET}"
if [ -n "$rate_str" ]; then
  printf '%b' "${base} ${DIM}|${RESET} ${YELLOW}${rate_str}${RESET}"
else
  printf '%b' "${base}"
fi
