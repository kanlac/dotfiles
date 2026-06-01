alias cc='claude --dangerously-skip-permissions'
alias oc='opencode'
alias codex='codex -c features.apps=false --dangerously-bypass-approvals-and-sandbox'
alias h='hermes --tui'

alias lg='lazygit'
alias yg='yadm enter lazygit'
alias og='lazygit --git-dir=$HOME/git-repos/obsidian-vault --work-tree="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian"'

# Antigravity Manager 更新
alias update-antigravity='~/bin/update-antigravity.sh'

# Copy files or directories from the Mac mini into the local Downloads directory.
cp2() {
    local remote_host="${MAC_MINI_SCP_HOST:-${USER}@kans-mac-mini}"

    if [ $# -eq 0 ]; then
        echo "Usage: cp2 <remote-path> [remote-path ...]"
        return 2
    fi

    local -a sources
    local remote_path
    for remote_path in "$@"; do
        sources+=("${remote_host}:${remote_path}")
    done

    command scp -r "${sources[@]}" "$HOME/Downloads/"
}

# Reattach to the Mac mini tmux session and silently reconnect after SSH drops.
ssh2() {
    emulate -L zsh

    local remote_user="${1:-${USER}}"
    local remote_host="${2:-${SSH2_HOST:-kans-mac-mini}}"
    local target ssh_exit

    if [[ "$remote_user" == *@* ]]; then
        target="$remote_user"
    else
        target="${remote_user}@${remote_host}"
    fi

    while true; do
        command ssh -tt -q \
            -o ServerAliveInterval=15 \
            -o ServerAliveCountMax=2 \
            -o ConnectTimeout=5 \
            -o BatchMode=yes \
            "$target" 'bash -lc "tmux attach"' 2>/dev/null
        ssh_exit=$?

        command stty sane 2>/dev/null
        if [[ -t 1 ]]; then
            printf '\033[?1l\033>\033[?7h\033[?12l\033[?25h'
            printf '\033[?1000l\033[?1002l\033[?1003l\033[?1004l\033[?1005l\033[?1006l\033[?1015l'
            printf '\033[?2004l'
        fi

        [[ "$ssh_exit" -eq 255 ]] || return "$ssh_exit"
        sleep 3
    done
}

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
