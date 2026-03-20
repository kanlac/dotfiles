# Git SSH 配置

- 默认使用 `github.com`（例如 `git@github.com:user/repo.git`）
- mindfit 项目使用 `mindfitgit` 作为 git SSH host

# Skill 编写规则

- **Skill 不能有外部依赖**：Skill 文档（SKILL.md 及其引用的子文档）中不能引用 Skill 目录外的文件路径（如 `docs/`、`data/`、`sql/` 等）。Skill 是自包含的方法论，不依赖项目中的具体文件。如果需要提示"参考已有样本"，用搜索指引（如"在项目中搜索 xxx"）代替硬编码路径。
- **Skill 写方向不写步骤**：方法论文档重点说明**意图和方向**（为什么要这么做、典型模板有哪些），而非详细的操作步骤。用 2-3 个典型示例启发 agent 理解目标，而不是写 step-by-step 教程。Agent 是有判断力的，给方向比给步骤更有效。

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
