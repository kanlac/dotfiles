#!/bin/sh
# Claude Code status line — two rows of block gauges
#   row 1:  branch │ model │ fast mode │ effort meter │ context gauge
#   row 2:  5h / 7d rate-limit gauges with reset clock │ full session id
#
# Theme: edit DEFAULT_THEME below. Override for previewing with
#   CC_STATUSLINE_THEME=neon sh ~/.claude/statusline-command.sh < sample.json
DEFAULT_THEME=nord
CLOCK_COLOR=110          # 重置时间的颜色（256 色号）；留空则跟随配色自带的
MARK='◷'              # 重置时间前面的记号

input=$(cat)

RESET='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
c() { printf '\033[38;5;%sm' "$1"; }   # 256-color foreground

FILL='█'; EMPTY='░'          # context / rate-limit gauges
PIP='▰';  PIP_OFF='▱'        # effort ladder

# ---- palettes ----------------------------------------------------------------
theme=${CC_STATUSLINE_THEME:-$DEFAULT_THEME}
case "$theme" in
  classic)  # 基础 ANSI 8 色，任何终端都对得上主题
    C_BRANCH='\033[0;32m'; C_MODEL='\033[0;35m'; C_BADGE=$DIM
    C_FAST_ON="${BOLD}\033[0;33m"; C_FAST_OFF=$DIM
    E1='\033[0;36m'; E2='\033[0;36m'; E3='\033[0;32m'; E4='\033[0;33m'; E5='\033[0;35m'
    G_LOW='\033[0;32m'; G_MID='\033[0;33m'; G_HIGH='\033[0;31m'; C_EMPTY=$DIM
    C_LABEL=$DIM; C_PCT=$DIM; C_SEP=$DIM; C_CLOCK='\033[0;36m'; C_SESSION='\033[0;34m' ;;
  mono)     # 灰阶石墨，只有濒临上限才见红
    C_BRANCH=$(c 250); C_MODEL=$(c 252); C_BADGE=$(c 240)
    C_FAST_ON="${BOLD}$(c 255)"; C_FAST_OFF=$(c 238)
    E1=$(c 240); E2=$(c 243); E3=$(c 246); E4=$(c 250); E5=$(c 255)
    G_LOW=$(c 248); G_MID=$(c 252); G_HIGH=$(c 203); C_EMPTY=$(c 236)
    C_LABEL=$(c 241); C_PCT=$(c 244); C_SEP=$(c 237); C_CLOCK=$(c 246); C_SESSION=$(c 240) ;;
  neon)     # 赛博高对比，暗背景下最跳
    C_BRANCH=$(c 48); C_MODEL=$(c 201); C_BADGE=$(c 141)
    C_FAST_ON="${BOLD}$(c 226)"; C_FAST_OFF=$(c 238)
    E1=$(c 45); E2=$(c 51); E3=$(c 48); E4=$(c 226); E5=$(c 201)
    G_LOW=$(c 51); G_MID=$(c 226); G_HIGH=$(c 198); C_EMPTY=$(c 236)
    C_LABEL=$(c 61); C_PCT=$(c 111); C_SEP=$(c 54); C_CLOCK=$(c 87); C_SESSION=$(c 99) ;;
  ember)    # 暖色炭火，橙琥珀为主
    C_BRANCH=$(c 179); C_MODEL=$(c 208); C_BADGE=$(c 130)
    C_FAST_ON="${BOLD}$(c 214)"; C_FAST_OFF=$(c 238)
    E1=$(c 137); E2=$(c 173); E3=$(c 215); E4=$(c 208); E5=$(c 202)
    G_LOW=$(c 143); G_MID=$(c 214); G_HIGH=$(c 160); C_EMPTY=$(c 235)
    C_LABEL=$(c 95); C_PCT=$(c 180); C_SEP=$(c 236); C_CLOCK=$(c 223); C_SESSION=$(c 131) ;;
  nord)     # 冷色 Nord，低饱和护眼
    C_BRANCH=$(c 108); C_MODEL=$(c 110); C_BADGE=$(c 60)
    C_FAST_ON="${BOLD}$(c 222)"; C_FAST_OFF=$(c 238)
    E1=$(c 109); E2=$(c 116); E3=$(c 108); E4=$(c 222); E5=$(c 139)
    G_LOW=$(c 108); G_MID=$(c 222); G_HIGH=$(c 167); C_EMPTY=$(c 237)
    C_LABEL=$(c 60); C_PCT=$(c 109); C_SEP=$(c 238); C_CLOCK=$(c 116); C_SESSION=$(c 139) ;;
esac

# 重置时间颜色：环境变量 > CLOCK_COLOR 旋钮 > 配色默认
[ -n "$CC_STATUSLINE_CLOCK" ] && CLOCK_COLOR=$CC_STATUSLINE_CLOCK
[ -n "$CC_STATUSLINE_MARK" ] && MARK=$CC_STATUSLINE_MARK
[ -n "$CLOCK_COLOR" ] && C_CLOCK=$(c "$CLOCK_COLOR")

# ---- one jq pass, shell-quoted ----------------------------------------------
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // .model.id // "unknown" | tostring)",
  @sh "model_id=\(.model.id // "" | tostring)",
  @sh "session_id=\(.session_id // "" | tostring)",
  @sh "ctx_pct=\(.context_window.used_percentage // "" | tostring)",
  @sh "fast=\(.fast_mode // false | tostring)",
  @sh "effort=\(.effort.level // "" | tostring)",
  @sh "five_pct=\(.rate_limits.five_hour.used_percentage // "" | tostring)",
  @sh "five_at=\(.rate_limits.five_hour.resets_at // "" | tostring)",
  @sh "week_pct=\(.rate_limits.seven_day.used_percentage // "" | tostring)",
  @sh "week_at=\(.rate_limits.seven_day.resets_at // "" | tostring)"
')"

git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

# "Opus 5 (1M context)" -> "Opus 5" + ·1M badge
badge=""
case "$model" in
  *"(1M context)") model=${model% (1M context)}; badge="1M" ;;
esac

# ---- width budget (Claude Code exports COLUMNS) -----------------------------
cols=${COLUMNS:-100}
if [ "$cols" -lt 90 ]; then ctx_w=10; rl_w=5; else ctx_w=16; rl_w=8; fi

pct_int() { [ -n "$1" ] && printf '%.0f' "$1" 2>/dev/null || printf '' ; }

# repeat a (possibly multi-byte) char n times, no forks — tr can't do UTF-8
rep() {
  _n=$1; _c=$2; _s=''
  while [ "$_n" -gt 0 ]; do _s="${_s}${_c}"; _n=$(( _n - 1 )); done
  printf '%s' "$_s"
}

# gauge: $1 = percent (int), $2 = cells  ->  █████░░░░░░░
gauge() {
  _p=$1; _w=$2
  _f=$(( _p * _w / 100 ))
  [ "$_f" -gt "$_w" ] && _f=$_w
  [ "$_f" -lt 0 ] && _f=0
  [ "$_f" -eq 0 ] && [ "$_p" -gt 0 ] && _f=1
  _c=$G_LOW
  [ "$_p" -ge 50 ] && _c=$G_MID
  [ "$_p" -ge 80 ] && _c=$G_HIGH
  printf '%b' "${_c}$(rep "$_f" "$FILL")${C_EMPTY}$(rep "$(( _w - _f ))" "$EMPTY")${RESET}"
}

# reset clock: epoch -> "17:18", or "Wed 15:18" when it lands on another day
clock() {
  [ -z "$1" ] && return
  _e=$(printf '%.0f' "$1" 2>/dev/null) || return
  _o=$(date -r "$_e" '+%j %a %H:%M' 2>/dev/null) \
     || _o=$(date -d "@$_e" '+%j %a %H:%M' 2>/dev/null) || return
  _rj=${_o%% *}; _rest=${_o#* }; _rw=${_rest%% *}; _rt=${_rest##* }
  if [ "$_rj" = "$(date '+%j')" ]; then printf '%s' "$_rt"; else printf '%s %s' "$_rw" "$_rt"; fi
}

SEP="${C_SEP} │ ${RESET}"

# ---- row 1 -------------------------------------------------------------------
row1=""
[ -n "$git_branch" ] && row1="${C_BRANCH}${git_branch}${RESET}${SEP}"
row1="${row1}${C_MODEL}${model}${RESET}"
[ -n "$badge" ] && row1="${row1}${C_BADGE}·${badge}${RESET}"

if [ "$fast" = "true" ]; then
  row1="${row1}${SEP}${C_LABEL}⚡fast${RESET} ${C_FAST_ON}on${RESET}"
else
  row1="${row1}${SEP}${C_LABEL}⚡fast${RESET} ${C_FAST_OFF}off${RESET}"
fi

# effort 档位数随模型而变：bundle 里 supportedEffortLevels 是全量表按
# max_effort / xhigh_effort 两个 capability 过滤的结果。
#   两个 capability 都有 → low medium high xhigh max（5 档）
#   只有 max_effort      → low medium high max      （4 档，没有 xhigh）
#   两个都没有           → 不支持 effort，字段本身缺席
mid=${model_id%%[*}                      # claude-opus-5[1m] -> claude-opus-5
case "$mid" in
  *sonnet-4-6*|*opus-4-6*) ladder="low medium high max" ;;
  *)                       ladder="low medium high xhigh max" ;;
esac

en=0; etotal=0; ec=""
for lv in $ladder; do
  etotal=$(( etotal + 1 ))
  [ "$lv" = "$effort" ] && en=$etotal
done
case "$effort" in                        # 颜色按档位名固定，不随档位数漂移
  low) ec=$E1 ;; medium) ec=$E2 ;; high) ec=$E3 ;; xhigh) ec=$E4 ;; max) ec=$E5 ;;
esac

if [ "$en" -gt 0 ]; then
  pips=""; i=1
  while [ "$i" -le "$etotal" ]; do
    [ "$i" -gt 1 ] && pips="${pips} "
    if [ "$i" -le "$en" ]; then pips="${pips}${ec}${PIP}"; else pips="${pips}${C_EMPTY}${PIP_OFF}"; fi
    i=$(( i + 1 ))
  done
  row1="${row1}${SEP}${C_LABEL}eff${RESET} ${pips}${RESET}  ${ec}${effort}${RESET}"
elif [ -n "$effort" ]; then
  # 档位表没猜中（新模型）：宁可只报名字，也不整段吞掉
  row1="${row1}${SEP}${C_LABEL}eff${RESET}  ${C_PCT}${effort}${RESET}"
fi

ci=$(pct_int "$ctx_pct")
if [ -n "$ci" ]; then
  row1="${row1}${SEP}${C_LABEL}ctx${RESET} $(gauge "$ci" "$ctx_w") ${C_PCT}${ci}%${RESET}"
else
  row1="${row1}${SEP}${C_LABEL}ctx ?${RESET}"
fi

# ---- row 2 -------------------------------------------------------------------
row2=""
fi_=$(pct_int "$five_pct")
if [ -n "$fi_" ]; then
  row2="${C_LABEL}5h${RESET} $(gauge "$fi_" "$rl_w") ${C_PCT}${fi_}%${RESET}"
  ft=$(clock "$five_at"); [ -n "$ft" ] && row2="${row2} ${C_LABEL}${MARK}${RESET} ${C_CLOCK}${ft}${RESET}"
fi
wi_=$(pct_int "$week_pct")
if [ -n "$wi_" ]; then
  [ -n "$row2" ] && row2="${row2}${SEP}"
  row2="${row2}${C_LABEL}7d${RESET} $(gauge "$wi_" "$rl_w") ${C_PCT}${wi_}%${RESET}"
  wt=$(clock "$week_at"); [ -n "$wt" ] && row2="${row2} ${C_LABEL}${MARK}${RESET} ${C_CLOCK}${wt}${RESET}"
fi
if [ -n "$session_id" ]; then
  [ -n "$row2" ] && row2="${row2}${SEP}"
  row2="${row2}${C_LABEL}session:${RESET}${C_SESSION}${session_id}${RESET}"
fi

printf '%b\n' "$row1"
[ -n "$row2" ] && printf '%b' "$row2"
