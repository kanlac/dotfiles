alias cco='CLAUDE_CODE_OAUTH_TOKEN=$CC_OAUTH_TOKEN claude --dangerously-skip-permissions'
alias cca='ANTHROPIC_BASE_URL=http://127.0.0.1:8045 ANTHROPIC_API_KEY=sk-antigravity ANTHROPIC_DEFAULT_HAIKU_MODEL=gemini-3-flash ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-5 ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-5-thinking claude --dangerously-skip-permissions'


# `oc` to open opencode in new tab with smaller font setting
oc() {
  # 缩小字体次数：默认 3 次（你可改 2/4）
  local numSteps=3

  # 构造命令：用 "$@" 保留参数结构
  local cmd="opencode"
  if [[ $# -gt 0 ]]; then
    cmd+=" "
    # 这里简单拼接；若你有带引号/空格的复杂参数，下面我再给"强健版"
    cmd+="$*"
  fi

  /usr/bin/osascript <<APPLESCRIPT
on run
  set theCmd to "${cmd}"
  set numSteps to ${numSteps}

  tell application "Ghostty" to activate
  tell application "System Events"
    -- 新开 tab
    keystroke "t" using {command down}
    delay 0.10

    -- 缩小字体 numSteps 次（⌘-）
    repeat numSteps times
      keystroke "-" using {command down}
      delay 0.03
    end repeat

    -- 粘贴命令并回车
    set the clipboard to theCmd
    keystroke "v" using {command down}
    keystroke return
  end tell
end run
APPLESCRIPT
}

