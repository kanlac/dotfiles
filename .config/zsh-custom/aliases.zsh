alias cc='claude --allow-dangerously-skip-permissions'
alias cco='CLAUDE_CODE_OAUTH_TOKEN=$CC_OAUTH_TOKEN claude --allow-dangerously-skip-permissions'
alias cca='ANTHROPIC_BASE_URL=http://127.0.0.1:8045 ANTHROPIC_API_KEY=sk-antigravity ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-sonnet-4-5 ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-5 ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-5-thinking claude --allow-dangerously-skip-permissions'
alias oc='opencode'
alias codex='codex --dangerously-bypass-approvals-and-sandbox'

alias lg='lazygit'
alias yg='yadm enter lazygit'

# Antigravity Manager 更新
alias update-antigravity='~/bin/update-antigravity.sh'

# tmux: 设置当前 window 的默认目录并重命名
tz() {
    local target_dir="${1:-.}"  # 默认使用当前目录

    # 展开为绝对路径
    target_dir=$(cd "$target_dir" 2>/dev/null && pwd)

    if [ $? -ne 0 ]; then
        echo "❌ Directory not found: $1"
        return 1
    fi

    # 检查是否在 tmux 中
    if [ -z "$TMUX" ]; then
        echo "❌ Not in a tmux session"
        return 1
    fi

    # 获取目录的 basename 作为 window 名称
    local window_name=$(basename "$target_dir")

    # 重命名当前 window
    tmux rename-window "$window_name"

    # 切换到目标目录
    cd "$target_dir"

    # 设置环境变量，供其他脚本使用
    export TMUX_WINDOW_ROOT="$target_dir"

    # 设置 tmux pane 的默认目录（用于 split-window）
    # 这会让在这个 window 中创建的新 pane 使用这个路径
    tmux set-option -w -t "$(tmux display-message -p '#I')" @default-path "$target_dir"

    echo "✓ Window renamed to: $window_name"
    echo "✓ Changed directory to: $target_dir"
}

