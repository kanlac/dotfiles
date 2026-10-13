#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Proxy On
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🟢
# @raycast.packageName Proxy
# @raycast.description 打开 Clash Verge 系统代理与 TUN 模式，并确保 Tailscale 已连接

source "$(dirname "$0")/_proxy-lib.sh"

msgs=()
fail=0

out=$(ensure_tailscale_up) || fail=1; msgs+=("$out")

if ensure_verge_running; then
  out=$(set_verge_switch enable_system_proxy "$KEYCODE_SYSTEM_PROXY" true "系统代理") || fail=1; msgs+=("$out")
  out=$(set_verge_switch enable_tun_mode "$KEYCODE_TUN" true "TUN") || fail=1; msgs+=("$out")
else
  msgs+=("Clash Verge：启动失败"); fail=1
fi

out=$(printf '%s；' "${msgs[@]}"); echo "${out%；}"
exit $fail
