#!/bin/bash
# Raycast「Proxy On / Proxy Off」共用逻辑（无 @raycast 元数据，Raycast 不会把它当成命令）。
#
# 原理：Clash Verge 的快捷键只能「翻转」开关，所以先读 verge.yaml 里的当前状态，
# 只对和目标不一致的开关模拟按下对应快捷键，切换仍由 Clash Verge 自己完成。
#
# 前提：在 Clash Verge「设置 → 热键设置」里绑定下面两组快捷键（改了这里要同步改那边）：
#   切换系统代理  ⌃⌥⇧⌘P
#   切换 TUN 模式 ⌃⌥⇧⌘T
# 并给 Raycast 开「辅助功能」权限（模拟按键需要）。

VERGE_YAML="$HOME/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/verge.yaml"
VERGE_APP="Clash Verge"
VERGE_PROC="Clash Verge.app/Contents/MacOS/clash-verge"
TAILSCALE_APP="Tailscale"
TAILSCALE_CLI="/usr/local/bin/tailscale"

# macOS 虚拟键码：P=35，T=17（与键盘布局无关）
KEYCODE_SYSTEM_PROXY=35
KEYCODE_TUN=17
HOTKEY_MODIFIERS="{control down, option down, shift down, command down}"

# ---------- Clash Verge ----------

verge_running() { pgrep -f "$VERGE_PROC" >/dev/null; }

# 读 verge.yaml 顶层字段，输出 true / false
verge_get() {
  local v
  v=$(grep -E "^$1:" "$VERGE_YAML" 2>/dev/null | head -1 | awk '{print $2}')
  [[ "$v" == "true" ]] && echo true || echo false
}

press_hotkey() {
  osascript -e "tell application \"System Events\" to key code $1 using $HOTKEY_MODIFIERS"
}

# 等字段变成目标值，最多约 timeout 秒
wait_verge_field() {
  local field=$1 want=$2 timeout=${3:-8} i
  for ((i = 0; i < timeout * 2; i++)); do
    [[ "$(verge_get "$field")" == "$want" ]] && return 0
    sleep 0.5
  done
  return 1
}

# set_verge_switch <字段> <键码> <目标 true|false> <显示名>
set_verge_switch() {
  local field=$1 keycode=$2 want=$3 label=$4
  if [[ "$(verge_get "$field")" == "$want" ]]; then
    echo "${label}：已是目标状态"
    return 0
  fi
  press_hotkey "$keycode" || { echo "${label}：模拟按键失败（检查 Raycast 辅助功能权限）"; return 1; }
  if wait_verge_field "$field" "$want"; then
    echo "${label}：已切换"
  else
    echo "${label}：按键已发送，但状态未变（检查 Clash Verge 快捷键绑定）"
    return 1
  fi
}

ensure_verge_running() {
  verge_running && return 0
  open -ga "$VERGE_APP"
  local i
  for ((i = 0; i < 30; i++)); do
    verge_running && { sleep 3; return 0; }  # 额外等快捷键注册完成
    sleep 0.5
  done
  return 1
}

# ---------- Tailscale ----------

tailscale_state() {
  "$TAILSCALE_CLI" status --json 2>/dev/null | /usr/bin/jq -r '.BackendState // empty'
}

ensure_tailscale_up() {
  if ! pgrep -x "$TAILSCALE_APP" >/dev/null; then
    open -ga "$TAILSCALE_APP"
  fi
  local i state
  for ((i = 0; i < 30; i++)); do
    state=$(tailscale_state)
    [[ -n "$state" && "$state" != "NoState" && "$state" != "Starting" ]] && break
    sleep 0.5
  done
  case "$state" in
    Running) echo "Tailscale：已连接" ;;
    Stopped)
      if "$TAILSCALE_CLI" up >/dev/null 2>&1; then
        echo "Tailscale：已连接"
      else
        echo "Tailscale：已启动，但连接失败（请在菜单栏手动连接）"
        return 1
      fi
      ;;
    NeedsLogin) echo "Tailscale：已启动，需要登录"; return 1 ;;
    *) echo "Tailscale：已启动，状态未知（${state:-无响应}）"; return 1 ;;
  esac
}

quit_tailscale() {
  if ! pgrep -x "$TAILSCALE_APP" >/dev/null; then
    echo "Tailscale：未在运行"
    return 0
  fi
  osascript -e "tell application \"$TAILSCALE_APP\" to quit"
  local i
  for ((i = 0; i < 20; i++)); do
    pgrep -x "$TAILSCALE_APP" >/dev/null || { echo "Tailscale：已退出"; return 0; }
    sleep 0.5
  done
  echo "Tailscale：退出超时"
  return 1
}
