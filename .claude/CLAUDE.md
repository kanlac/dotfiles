# Dotfiles 管理

- 使用 [yadm](https://yadm.io) 管理个人配置文件，详见 `~/README.md`

# Git SSH 配置

- 默认使用 `github.com`（例如 `git@github.com:user/repo.git`）
- mindfit 项目使用 `mindfitgit` 作为 git SSH host

# Git 历史重写禁令

- **不要用 `git filter-branch`**：它会重写整棵 commit 树的 hash，导致分支与 master 断开共同祖先，GitHub 上无法正常 diff/PR。cherry-pick 重建分支时极易丢失文件（亲历：base.css 和 main.js 改动丢失，全站样式崩溃）
- **从历史中删文件的正确做法**：在新 commit 里 `git rm` + 加 `.gitignore`，不重写历史。如果确实需要清除敏感数据，用 `git filter-repo`（比 filter-branch 安全）
- **重建分支后必须验证**：如果不得已做了 cherry-pick 重建，必须检查关键文件（入口文件、配置文件、CSS 入口）是否完整，跑一遍 `git diff` 确认改动数量与预期一致

# Skill 优先原则

- **有专门 Skill 可用时，必须优先调用 Skill，不要因为"觉得自己能搞定"就绕过**。Skill 封装了专门的流程和质量保障（如 `skill-creator:skill-creator` 用于创建 skill，`superpowers:writing-plans` 用于写计划），跳过它等于放弃专门工具的价值。即使当前上下文已经充足，Skill 的流程本身也是一层额外的质量检查。

# Skill 编写规则

- **Skill 不能有外部依赖**：Skill 文档（SKILL.md 及其引用的子文档）中不能引用 Skill 目录外的文件路径（如 `docs/`、`data/`、`sql/` 等）。Skill 是自包含的方法论，不依赖项目中的具体文件。如果需要提示"参考已有样本"，用搜索指引（如"在项目中搜索 xxx"）代替硬编码路径。
- **Skill 写方向不写步骤**：方法论文档重点说明**意图和方向**（为什么要这么做、典型模板有哪些），而非详细的操作步骤。用 2-3 个典型示例启发 agent 理解目标，而不是写 step-by-step 教程。Agent 是有判断力的，给方向比给步骤更有效。
- **Skill 要写成通用的**：不要引用个人特有的工具链或配置（如 `agents.json`、`yadm bootstrap`、特定 tmux session 名），而是用通用描述。Skill 面向所有用户，不是只给自己用的备忘录。

# Chrome 浏览器自动化（强制规则）

**凡是需要有头（GUI）Chrome 的场景，必须先 invoke `steroids:cdp-chrome` Skill，然后严格遵循其规则。**

适用场景（不限于）：
- 访问社交媒体：X/Twitter 浏览/发帖、Reddit 采集帖子、Instagram 等
- **读取社交媒体页面内容**：读取推文、帖子等内容时，直接用 CDP Chrome + `take_snapshot`，**不要先尝试 defuddle 或 WebFetch**——这些工具在社交媒体上必定失败（JS 渲染 + 反爬）
- 新闻/文章核实：检查发布日期、获取 JS 渲染页面
- 需要登录态的网站操作
- 反自动化检测的网站访问
- 网页表单交互、截图

不适用：无头测试自有代码、PDF 生成、Playwright/Puppeteer 单元测试

**禁止自行启动 Chrome 实例。** 所有 agent 共用一个干净的共享 Chrome（`~/.config/cdp-chrome/`），通过 `mcp__chrome-devtools__*` 工具或直连 CDP API 操作。

# 代理配置

- 通过 `~/.env` 中的 `PROXY=on` 控制代理开关
- `~/.zshrc` 读取 `PROXY` 变量，当值为 `on` 时 export HTTP/SOCKS5 代理环境变量（`http_proxy`, `all_proxy` 等），地址为 `127.0.0.1:7890`
- SSH 代理（`~/.ssh/config`）通过 `ProxyCommand` 检测 `$all_proxy` 是否存在来决定是否走 SOCKS5 代理，不硬编码地址
- 关闭代理：在 `~/.env` 中删除或注释 `PROXY=on`，然后重启 shell

# CLAUDE.md 文件区分

- **用户 CLAUDE.md**（`~/.claude/CLAUDE.md`）：全局指令，跨所有项目生效。用户说「更新用户 CLAUDE.md」指的是这个文件
- **项目 CLAUDE.md**（项目根目录 `CLAUDE.md`）：项目专属指令。用户说「更新项目 CLAUDE.md」或未特别指定时，根据内容性质判断归属
- 严格区分：全局通用的知识（如 Skill 编写规则、代理配置、Teammate vs Subagent）放用户 CLAUDE.md；项目专属的知识（如数据库 schema、任务编排、行业配置）放项目 CLAUDE.md

# Teammate vs Subagent

严格区分这两个概念，用户说哪个就用哪个：

- **Teammate**（用户说「启动 teammate」「用 teammate」）：通过 `TeamCreate` 创建 team → `TaskCreate` 建任务 → `Agent` tool 带 `team_name` + `name` 参数 spawn。Teammate 是独立的 Claude Code 实例，用户可直接交互（Shift+Down 切换），teammate 之间可互相通信，通过共享 task list 协调
- **Subagent**（用户说「用 subagent」）：通过 `Agent` tool 不带 `team_name` spawn。在主会话内运行，结果只返回给主 agent，用户无法直接交互
- 用户说「teammate」时绝不能用 subagent 代替，反之亦然

# Agent Steroids 项目

- 用于存放共享的、公开的 Claude 插件，个人专属的 skill 放全局 `~/.claude/` 下，不放这个项目
- 项目路径：`/Users/kan/Documents/agent-steroids`
- Skill 放在 `skills/` 子目录，Command 放在 `commands/` 子目录

# 计划文档编写规则

- **闭环**：计划必须从开始执行到最终验证形成完整闭环。不能停在"更新完配置"就结束——必须包含端到端测试、数据校验等步骤，确保改动真正生效
- **每个 Phase 有验证**：每个阶段结束时必须有可执行的验证步骤（命令、脚本、SQL 查询），不能只写"检查是否正确"
- **标注人工确认节点**：需要用户决策的节点用醒目标记（如 🔵），并明确说明需要用户确认什么。其余 Phase 默认自主执行，尽量减少用户介入

# 文档和代码规范

- **不要在文档/代码中硬编码用户名**：Skill 文档、脚本、配置示例中使用 `$HOME`、`~`、`$USER` 等变量或占位符，不要出现具体的用户名（如 `/Users/kan/`）

# 文档查询

- **不要用 Context7 MCP 查 Claude Code 文档**：Context7 的索引有滞后，查不到新版本的字段和功能。查 Claude Code 最新文档用 `defuddle parse "https://docs.anthropic.com/en/docs/claude-code/<page>" --md` 直接抓官网


# Telegram Channel 交互

- 收到 Telegram 消息后，先对该消息发送一个 👀 emoji react，表示正在处理，然后再开始实际工作
- **当会话接入了 Telegram channel 时，所有回复都通过 Telegram reply 工具发送，不在终端输出回复内容**。终端只用于执行工具调用（查数据库、读文件等），最终结果回复到 Telegram
- **Telegram 文件上传失败时**：Telegram plugin 的文件发送在 proxy 环境下会失败（Bun TLS bug，详见 `steroids:telegram-agents` Skill 的「Bun Proxy 文件上传问题」章节）。遇到 `Network request for 'sendDocument' failed!` 时，用 curl 直接调 Bot API 绕过：从状态目录的 `.env` 读 bot token，然后 `curl -X POST "https://api.telegram.org/bot$TOKEN/sendDocument" -F chat_id=<id> -F "document=@<path>"`
