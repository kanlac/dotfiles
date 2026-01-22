# ~/.oh-my-zsh/custom/oc.zsh
# OpenCode: open in a new iTerm2 tab using a dedicated iTerm2 profile (small font)

oc() {
  local OPENCODE_PROFILE="opencode"  # 改成你的 iTerm2 小字体 profile 名

  # 拼接参数（简单版）
  local args=""
  if [ "$#" -gt 0 ]; then
    args=" $*"
  fi

  osascript <<OSA
tell application "iTerm2"
  activate
  set p to "$OPENCODE_PROFILE"

  if (count of windows) = 0 then
    set w to (create window with profile p)
  else
    set w to current window
    tell w
      set t to (create tab with profile p)
    end tell
  end if

  tell current session of w
    write text "opencode$args"
  end tell
end tell
OSA
}
