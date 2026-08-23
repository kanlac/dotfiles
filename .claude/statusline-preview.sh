#!/bin/sh
# 预览 / 应用 status line 外观
#   sh ~/.claude/statusline-preview.sh              5 套配色
#   sh ~/.claude/statusline-preview.sh --clock      重置时间的颜色候选
#   sh ~/.claude/statusline-preview.sh --mark       重置时间的记号候选
#   sh ~/.claude/statusline-preview.sh --set nord | --set-clock 222 | --set-mark ⟳
SL="$HOME/.claude/statusline-command.sh"
THEMES="classic mono neon ember nord"

setkey() { # $1=变量名 $2=值
  python3 - "$SL" "$1" "$2" <<'PY'
import re, sys
p, key, val = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p).read()
q = "'" if key == "MARK" else ""
s = re.sub(r'(?m)^%s=\S*' % key, '%s=%s%s%s' % (key, q, val, q), s, count=1)
open(p, 'w').write(s)
PY
}

case "$1" in
  --set)       case " $THEMES " in *" $2 "*) ;; *) echo "未知配色: $2（可选: $THEMES）"; exit 1;; esac
               setkey DEFAULT_THEME "$2"; echo "配色 → $2"; exit 0 ;;
  --set-clock) setkey CLOCK_COLOR "$2"; echo "重置时间颜色 → $2"; exit 0 ;;
  --set-mark)  setkey MARK "$2"; echo "重置记号 → $2"; exit 0 ;;
esac

if [ -t 1 ]; then COLUMNS=$(tput cols 2>/dev/null); fi
: "${COLUMNS:=120}"; export COLUMNS
now=$(date +%s); five=$((now + 7200)); week=$((now + 3 * 86400))

sample() { # $1=ctx $2=5h $3=7d $4=fast $5=effort
  printf '{"model":{"display_name":"Opus 5 (1M context)"},"session_id":"6352fa26-3937-4a82-8435-3c5ac8e78650",'
  printf '"fast_mode":%s,"effort":{"level":"%s"},"context_window":{"used_percentage":%s},' "$4" "$5" "$1"
  printf '"rate_limits":{"five_hour":{"used_percentage":%s,"resets_at":%s},' "$2" "$five"
  printf '"seven_day":{"used_percentage":%s,"resets_at":%s}}}' "$3" "$week"
}
# 判断颜色/记号只看额度段，去掉 session id 让各行等长、便于横向比对
row2() {
  printf '{"session_id":"","rate_limits":{"five_hour":{"used_percentage":28,"resets_at":%s},' "$five"
  printf '"seven_day":{"used_percentage":29,"resets_at":%s}}}' "$week"
}

case "$1" in
  --clock)
    printf '\n\033[1m重置时间的颜色\033[0m（都在 Nord 底子上）\n\n'
    for e in "116 当前·淡霜蓝" "110 深霜蓝" "117 亮天蓝" "222 琥珀" "216 蜜桃" \
             "173 陶土橙" "139 紫藤" "175 玫瑰" "108 苔绿" "250 中性浅灰"; do
      code=${e%% *}; name=${e#* }
      printf '  \033[2m%3s\033[0m  ' "$code"
      row2 | CC_STATUSLINE_CLOCK=$code sh "$SL" | tail -1
      printf '   \033[2m%s\033[0m\n' "$name"
    done
    printf '\n选定： \033[1msh ~/.claude/statusline-preview.sh --set-clock <色号>\033[0m\n'
    exit 0 ;;
  --mark)
    printf '\n\033[1m重置时间的记号\033[0m\n\n'
    for e in "重置 当前" "回血 口语" "恢复 中性" "刷新 偏动作" "下次 偏时点" \
             "↻ 回环" "◷ 钟面" "⧖ 沙漏" "→ 箭头" "@ at"; do
      m=${e%% *}; name=${e#* }
      printf '  %s  ' "$m"
      row2 | CC_STATUSLINE_MARK="$m" sh "$SL" | tail -1
      printf '   \033[2m%s\033[0m\n' "$name"
    done
    printf '\n选定： \033[1msh ~/.claude/statusline-preview.sh --set-mark <记号>\033[0m\n'
    exit 0 ;;
esac

for t in $THEMES; do
  printf '\n\033[1m── %s ──\033[0m\n' "$t"
  sample 31 28 29 false xhigh | CC_STATUSLINE_THEME=$t sh "$SL"; printf '\n'
  sample 88 74 91 true max   | CC_STATUSLINE_THEME=$t sh "$SL"; printf '\n'
done
printf '\n选定： \033[1msh ~/.claude/statusline-preview.sh --set <名字>\033[0m   （%s）\n' "$THEMES"
