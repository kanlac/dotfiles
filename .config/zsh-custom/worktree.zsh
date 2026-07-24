# Git worktree 管理
# 规范：所有 worktree 统一放在 $WORKTREE_ROOT/<repo>/<name>（默认 ~/worktrees），
# 并为每个有 worktree 的仓库维护 $WORKTREE_ROOT/<repo>.code-workspace（VS Code 多根
# workspace，方便 Remote-SSH 打开）。workspace 文件由 git worktree list 自动生成，勿手改。
#
# 用法：
#   wt add <name>   在当前仓库建分支 <name> 的 worktree（分支已存在则复用），重生成 workspace
#   wt rm  <name>   删除该 worktree（分支保留），重生成 workspace
#   wt ls           列出当前仓库的所有 worktree

: ${WORKTREE_ROOT:="$HOME/worktrees"}

# 从当前所在的 git 仓库（主 worktree 或任一 worktree 内）定位主 worktree 的绝对路径
_wt_main() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  print -r -- "${common:h}"
}

# 依据 git worktree list 重新生成某仓库的 .code-workspace
_wt_gen_workspace() {
  local main=$1
  local repo=${main:t}
  local ws="$WORKTREE_ROOT/$repo.code-workspace"
  local -a paths
  local line
  mkdir -p "$WORKTREE_ROOT"
  while IFS= read -r line; do
    paths+=("${line#worktree }")
  done < <(git -C "$main" worktree list --porcelain | grep '^worktree ')
  {
    print -- '{'
    print -- '  "folders": ['
    local i
    for i in {1..$#paths}; do
      local comma=','
      [[ $i -eq $#paths ]] && comma=''
      print -- "    { \"path\": \"${paths[$i]}\" }$comma"
    done
    print -- '  ],'
    print -- '  "settings": {}'
    print -- '}'
  } > "$ws"
  print -- "workspace: $ws"
}

wt() {
  local cmd=$1
  shift 2>/dev/null
  case $cmd in
    add)
      local name=$1
      [[ -z $name ]] && { print -u2 "用法: wt add <name>"; return 1; }
      local main; main=$(_wt_main) || { print -u2 "不在 git 仓库内"; return 1; }
      local dir="$WORKTREE_ROOT/${main:t}/$name"
      if git -C "$main" show-ref --verify --quiet "refs/heads/$name"; then
        git -C "$main" worktree add "$dir" "$name" || return 1
      else
        git -C "$main" worktree add "$dir" -b "$name" || return 1
      fi
      _wt_gen_workspace "$main"
      print -- "已创建: $dir"
      ;;
    rm|remove)
      local name=$1
      [[ -z $name ]] && { print -u2 "用法: wt rm <name>"; return 1; }
      local main; main=$(_wt_main) || { print -u2 "不在 git 仓库内"; return 1; }
      local dir="$WORKTREE_ROOT/${main:t}/$name"
      git -C "$main" worktree remove "$dir" || return 1
      _wt_gen_workspace "$main"
      print -- "已删除: $dir（分支 $name 保留，如需删除: git -C \"$main\" branch -d $name）"
      ;;
    ls|list)
      local main; main=$(_wt_main) || { print -u2 "不在 git 仓库内"; return 1; }
      git -C "$main" worktree list
      ;;
    *)
      print -- "用法: wt add <name> | wt rm <name> | wt ls"
      ;;
  esac
}
