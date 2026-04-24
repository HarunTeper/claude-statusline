#!/usr/bin/env bash
input=$(cat)

# ── ANSI color codes ───────────────────────────────────────────────────────────
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
BLUE='\033[34m'
RESET='\033[0m'

# ── Parse JSON input ───────────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
effort=$(echo "$input" | jq -r '.model.reasoning_effort // empty')
if [ -z "$effort" ]; then
  settings_model=$(jq -r '.model // empty' "${HOME}/.claude/settings.json" 2>/dev/null)
  case "$settings_model" in
    *plan*)  effort="plan" ;;
    *fast*)  effort="fast" ;;
  esac
fi
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# ── Git branch ─────────────────────────────────────────────────────────────────
branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$(echo "$input" | jq -r '.workspace.current_dir // "."')" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# ── make_bar PCT LABEL ─────────────────────────────────────────────────────────
make_bar() {
  local pct_int
  pct_int=$(printf '%.0f' "${1:-0}")
  local label="$2"

  local filled=$(( pct_int / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  local empty=$(( 10 - filled ))

  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done

  local COLOR
  if [ "$pct_int" -ge 80 ]; then COLOR="$RED"
  elif [ "$pct_int" -ge 50 ]; then COLOR="$YELLOW"
  else COLOR="$GREEN"
  fi

  printf '%b' "${COLOR}${label}:[${bar}] ${pct_int}%${RESET}"
}

# ── format_resets_at UNIX_TIMESTAMP ───────────────────────────────────────────
format_resets_at() {
  local resets_at="$1"
  local now
  now=$(date +%s)
  local diff=$(( resets_at - now ))
  local time_str
  time_str=$(date -d "@${resets_at}" '+%H:%M' 2>/dev/null || date -r "${resets_at}" '+%H:%M' 2>/dev/null)
  if [ "$diff" -le 0 ]; then
    printf '%s (now)' "$time_str"
    return
  fi
  local h=$(( diff / 3600 ))
  local m=$(( (diff % 3600) / 60 ))
  local countdown
  if [ "$h" -gt 0 ]; then
    countdown=$(printf '%dh%02dm' "$h" "$m")
  else
    countdown=$(printf '%dm' "$m")
  fi
  printf '%s (%s)' "$time_str" "$countdown"
}

# ── Context usage ──────────────────────────────────────────────────────────────
ctx_total_k=$(echo "$ctx_size" | awk '{printf "%dk", $1/1000}')
if [ -n "$used_pct" ]; then
  used_k=$(awk "BEGIN{printf \"%dk\", ($ctx_size * $used_pct / 100) / 1000}")
  ctx_str=$(awk "BEGIN{printf \"ctx:%.0f%% (%s/%s)\", $used_pct, \"$used_k\", \"$ctx_total_k\"}")
else
  ctx_str="ctx:${ctx_total_k}"
fi

# ── Assemble output ────────────────────────────────────────────────────────────
model_str="${model}"
[ -n "$effort" ] && model_str="${model} (${effort})"
out="${CYAN}${model_str}${RESET}"
[ -n "$branch" ] && out="${out}  ${GREEN}${branch}${RESET}"
out="${out}  ${MAGENTA}${ctx_str}${RESET}"

[ -n "$session_cost" ] && out="${out}  ${BLUE}\$$(LC_ALL=C awk "BEGIN{printf \"%.2f\", $session_cost}")${RESET}"

if [ -n "$five_hour_pct" ]; then
  out="${out}  $(make_bar "$five_hour_pct" "5h")"
  [ -n "$five_hour_resets" ] && out="${out}  ${YELLOW}↺ $(format_resets_at "$five_hour_resets")${RESET}"
fi
if [ -n "$seven_day_pct" ]; then
  out="${out}  $(make_bar "$seven_day_pct" "7d")"
  [ -n "$seven_day_resets" ] && out="${out}  ${YELLOW}↺ $(format_resets_at "$seven_day_resets")${RESET}"
fi

printf '%b' "$out"
