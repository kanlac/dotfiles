# 我的 Dotfiles

使用 [yadm](https://yadm.io) 管理的个人配置文件。

## 🚀 快速开始（新机器设置）

### 1. 安装 yadm

```bash
# macOS
brew install yadm

# Linux (Debian/Ubuntu)
sudo apt install yadm

# 或者使用 curl
curl -fLo /usr/local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm && chmod a+x /usr/local/bin/yadm
```

### 2. 克隆配置

```bash
# 使用 SSH（推荐）
yadm clone git@github.com:kanlac/dotfiles.git

# 或者使用 HTTPS
yadm clone https://github.com/kanlac/dotfiles.git
```

如果遇到文件冲突，可以使用：
```bash
yadm clone git@github.com:kanlac/dotfiles.git --bootstrap
# 如果有冲突，先备份后强制覆盖
yadm reset --hard origin/main
```

### 3. 运行 bootstrap 脚本

```bash
yadm bootstrap
```

这个脚本会自动安装：
- Homebrew（macOS）
- 开发工具：
  - Neovim（文本编辑器）
  - ripgrep（快速文本搜索）
  - fd（快速文件查找）
  - fzf（模糊查找工具）
  - jq（JSON 处理工具）
  - im-select（输入法切换工具，macOS）
- 终端工具：
  - zoxide（智能目录跳转）
  - Ghostty（现代终端模拟器）
- Shell 配置：
  - oh-my-zsh
  - zsh-autosuggestions 插件
  - zsh-syntax-highlighting 插件
- Coding Agents（Claude Code、OpenCode 的 MCP servers 和插件）

在 macOS 上，bootstrap 还会检查 Chrome 网络 fail-closed 配置描述文件是否已安装。首次设置需要在“系统设置 → 通用 → 设备管理”中人工批准一次；验收以 `chrome://policy` 同时显示 `WebRtcIPHandling=disable_non_proxied_udp` 和 `DnsOverHttpsMode=off` 为准。

### 4. 创建环境变量文件

⚠️ **重要**：`~/.env` 文件包含敏感信息，不会被同步到 Git。需要手动创建：

```bash
# 创建 .env 文件
touch ~/.env
chmod 600 ~/.env

# 编辑并添加你的环境变量
nano ~/.env
```

示例内容：
```bash
# Claude Code OAuth Token
export CC_OAUTH_TOKEN=sk-ant-oat01-xxxxx

# 其他敏感环境变量
export SOME_API_KEY=xxxxx
```

### 5. 重启 Shell

```bash
source ~/.zshrc
# 或者重新打开终端
```

## 📁 文件结构

```
~
├── README.md                       # 本文件
├── CLAUDE.md -> README.md          # 软链接，供 Claude Code 读取
├── yadm-docs/                      # 方案文档
│   └── coding-agents-scheme.md     # Coding Agents 方案说明
├── .zshrc                          # Zsh 主配置文件
├── .claude/
│   └── settings.json               # Claude Code hooks 和 plugins 配置
├── .config/
│   ├── yadm/
│   │   ├── bootstrap               # 自动安装脚本
│   │   ├── scripts/render-clash-verge # 单独渲染 Clash Verge 全局脚本
│   │   └── ignore                  # yadm gitignore 规则
│   ├── clash-verge/
│   │   └── Script.js.tpl           # 公开模板；节点来自 Git 忽略的私密 JSON
│   ├── chrome/
│   │   └── WebRTCPolicy.mobileconfig # Chrome 全 profile / 无痕 WebRTC policy
│   ├── agents.json                 # Coding Agents 统一配置源
│   ├── nvim/
│   │   ├── init.lua                # Neovim 配置
│   │   └── lazy-lock.json          # lazy.nvim 插件锁定文件
│   └── zsh-custom/
│       └── aliases.zsh             # 自定义别名 (ZSH_CUSTOM 目录)
├── Library/
│   └── Application Support/
│       └── com.mitchellh.ghostty/
│           └── config                   # Ghostty 终端配置
└── .env                            # ⚠️ 本地环境变量（不会同步）
```

## 🛠️ 常用命令

### 查看变更

```bash
# 查看文件状态
yadm status

# 查看具体改动
yadm diff

# 使用 lazygit 可视化界面
yadm enter lazygit
```

### 提交变更

```bash
# 添加文件
yadm add ~/.zshrc

# 提交
yadm commit -m "Update zsh config"

# 推送到 GitHub
yadm push
```

### 同步配置

```bash
# 拉取最新配置
yadm pull

# 查看提交历史
yadm log --oneline
```

### 添加新配置文件

```bash
# 添加新文件到 yadm
yadm add ~/.gitconfig

# 查看已跟踪的文件
yadm list -a
```

## 🔧 包含的工具和插件

### Oh-My-Zsh 插件

- **git** - Git 命令别名和提示
- **zoxide** - 智能目录跳转（使用 `z` 命令）
- **zsh-autosuggestions** - 基于历史的命令建议（按 → 接受）
- **zsh-syntax-highlighting** - 实时语法高亮

### 自定义配置

所有自定义的 zsh 配置文件都在 `~/.config/zsh-custom/` 目录下，会自动链接到 oh-my-zsh。

### Neovim

**配置文件**：`~/.config/nvim/init.lua`

**特性**：
- 使用 [lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件
- 浅色主题（gruvbox-light）
- 自动输入法切换（需要 im-select）
- 离开焦点自动保存
- 系统剪贴板集成

**首次使用**：
```bash
# 打开 Neovim，lazy.nvim 会自动安装插件
nvim

# 手动同步插件（如果需要）
:Lazy sync
```

**包含的插件**：
- vim-surround - 快速环绕操作
- gruvbox.nvim - 主题
- fzf-lua - 模糊查找工具（文件搜索、文本搜索等）

**fzf-lua 快捷键**：
- `,ff` - 查找文件（支持软链接目录）
- `,fg` - 全局搜索文本（支持软链接目录）
- `,fb` - 查找已打开的 Buffer
- `,fh` - 查找帮助文档
- `,fo` - 最近打开的文件

### 命令行工具

**ripgrep (rg)** - 超快的文本搜索工具
```bash
# 搜索文本（自动忽略 .gitignore 的文件）
rg "search term"

# 搜索并显示上下文
rg -C 3 "search term"

# 跟随软链接搜索
rg --follow "search term"
```

**fd** - 超快的文件查找工具
```bash
# 查找文件
fd filename

# 查找并跟随软链接
fd --follow filename

# 查找特定类型的文件
fd -e js -e ts  # 只查找 .js 和 .ts 文件
```

**fzf** - 通用的模糊查找工具
```bash
# 快捷键（已自动配置）
# Ctrl+T - 在当前目录查找文件并插入路径
# Ctrl+R - 搜索命令历史
# Alt+C - 模糊搜索目录并跳转
```

### Ghostty

**配置文件**：`~/Library/Application Support/com.mitchellh.ghostty/config`

**特性**：
- 自动跟随系统主题（Gruvbox Dark/Light）
- 半透明背景 + 模糊效果
- Monaco 字体
- Cmd+J 发送 Esc（方便 Vim 使用）
- Cmd+Left/Right 切换标签页

**常用命令**：
```bash
# 列出可用主题
ghostty +list-themes

# 列出可用字体
ghostty +list-fonts
```

### Coding Agents (Claude Code / OpenCode)

**配置文件**：`~/.config/yadm/coding-agents.json`

统一管理 Claude Code 和 OpenCode 的 MCP servers 及 Claude 插件。

**工作原理**：
- `yadm bootstrap` 读取 `coding-agents.json`
- 合并 MCP servers 到 `~/.claude.json` 和 `~/.config/opencode/opencode.json`
- 自动安装 Claude plugins

**详细文档**：见 `~/.config/yadm/docs/coding-agents-scheme.md`

**手动添加本地 MCP server**（如带 auth 的 playwright）：
```bash
# 直接编辑目标配置文件，不会被 bootstrap 覆盖
# Claude: ~/.claude.json
# OpenCode: ~/.config/opencode/opencode.json
```

## 🔒 安全说明

### 被 gitignore 的文件

以下文件类型**不会**被同步到 Git：

- `.env` 和所有 `*.env` 文件
- SSH 密钥（`id_rsa`, `id_ed25519` 等）
- API tokens 和 secrets
- AWS credentials
- 其他敏感文件（见 `.config/yadm/ignore`）

### ⚠️ 添加新文件前请检查

```bash
# 添加文件前先查看内容
cat ~/.some-config

# 确保没有敏感信息后再添加
yadm add ~/.some-config
```

## 📱 推荐工具

### lazygit - Git 可视化界面

```bash
# 安装
brew install lazygit

# 在 yadm 中使用
yadm enter lazygit
```

在 lazygit 中你可以：
- 可视化查看所有变更
- 轻松 stage/unstage 文件
- 查看彩色 diff
- 提交和推送

快捷键：
- `Tab` - 切换面板
- `Enter` - 查看详细 diff
- `Space` - stage/unstage
- `c` - 提交
- `P` - push
- `?` - 帮助

## 🆘 常见问题

### Q: 在新机器上克隆后文件冲突怎么办？

```bash
# 备份现有配置
mv ~/.zshrc ~/.zshrc.backup

# 强制使用远程配置
yadm reset --hard origin/main
```

### Q: 如何更新 oh-my-zsh 插件？

```bash
# 进入插件目录并更新
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git pull

cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git pull
```

### Q: 如何查看 yadm 仓库位置？

```bash
yadm rev-parse --git-dir
# 输出: /Users/你的用户名/.local/share/yadm/repo.git
```

### Q: 不小心添加了敏感文件怎么办？

```bash
# 从 yadm 中移除（但保留本地文件）
yadm rm --cached ~/.sensitive-file

# 提交删除记录
yadm commit -m "Remove sensitive file"

# 如果已经推送到远程，需要重写历史（谨慎操作）
yadm filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .sensitive-file" \
  --prune-empty --tag-name-filter cat -- --all

# 强制推送
yadm push origin --force --all
```

## 📚 参考资料

- [yadm 官方文档](https://yadm.io)
- [Oh My Zsh](https://ohmyz.sh)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zoxide](https://github.com/ajeetdsouza/zoxide)

## 📝 License

MIT License - 随意使用和修改

---

最后更新：2026-01-22
