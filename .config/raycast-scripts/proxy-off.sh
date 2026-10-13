#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Proxy Off
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🔴
# @raycast.packageName Proxy
# @raycast.description 关闭 Clash Verge 系统代理与 TUN 模式，并退出 Tailscale

source "$(dirname "$0")/_proxy-lib.sh"

msgs=()
fail=0

if verge_running; then
  out=$(set_verge_switch enable_tun_mode "$KEYCODE_TUN" false "TUN") || fail=1; msgs+=("$out")
  out=$(set_verge_switch enable_system_proxy "$KEYCODE_SYSTEM_PROXY" false "系统代理") || fail=1; msgs+=("$out")
else
  msgs+=("Clash Verge：未在运行")
fi

out=$(quit_tailscale) || fail=1; msgs+=("$out")

out=$(printf '%s；' "${msgs[@]}"); echo "${out%；}"
exit $fail
