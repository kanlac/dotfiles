# Dotfiles 管理

- 使用 [yadm](https://yadm.io) 管理个人配置文件，详见 `~/README.md`

# Hermes

- `~/.hermes` 是 Nous Research 的开源 AI agent 平台 hermes-agent：https://github.com/NousResearch/hermes-agent

# Git SSH 配置

- 默认使用 `github.com`（例如 `git@github.com:user/repo.git`）
- mindfit 项目使用 `mindfitgit` 作为 git SSH host

# Git 历史重写禁令

- **不要用 `git filter-branch`**：它会重写整棵 commit 树的 hash，导致分支与 master 断开共同祖先，GitHub 上无法正常 diff/PR。cherry-pick 重建分支时极易丢失文件（亲历：base.css 和 main.js 改动丢失，全站样式崩溃）
- **从历史中删文件的正确做法**：在新 commit 里 `git rm` + 加 `.gitignore`，不重写历史。如果确实需要清除敏感数据，用 `git filter-repo`（比 filter-branch 安全）
- **重建分支后必须验证**：如果不得已做了 cherry-pick 重建，必须检查关键文件（入口文件、配置文件、CSS 入口）是否完整，跑一遍 `git diff` 确认改动数量与预期一致

# Git Worktree 规范

- worktree 建在仓库的同级目录，命名为 `<repo>-<name>`，命令 `git worktree add ../<repo>-<name> -b <branch>`（path 必填，git 无默认值）。例如仓库 `~/Documents/lawyer`，worktree 路径为 `~/Documents/lawyer-ocr-clean`。
- Claude Code 的 `isolation: "worktree"` 默认放在 `.claude/worktrees/`，与本规范不符；如需手动创建 worktree，按上述同级目录规范执行。

# GitHub 评论发布规则

- 需要在 GitHub issue/PR 上发布评论、回复维护者、解释问题或补充信息时，先把拟发布内容作为草稿发给用户确认；用户明确同意后再调用 GitHub/`gh` 写入。除非用户在当前消息中明确要求“直接发/帮我回复”，否则不要代发。

# 解压含中文文件名的 zip

- **不要用系统 `unzip` 或命令行 `ditto`**：它们按 cp437 / Mac Roman 瞎解中文名，得到一堆乱码（GUI Archive Utility 反而正常，因为它会读 0x7075）
- **正确做法**：用 Python `zipfile` 解，并**优先读每个条目的 `0x7075`（Info-ZIP Unicode Path）扩展字段**取真实 UTF-8 名，无该字段再按 GBK 转码兜底；同时跳过 `__MACOSX`、防 zip-slip
- **损坏/截断的 zip**：先诊断（查末尾有无 EOCD `PK\x05\x06`、最后一个本地头 `PK\x03\x04` 位置、尾部是否全零）。若数据被截断（尾部大段零填充），任何工具都救不回缺失部分，只能用 `zip -FF in --out out` 重建中央目录抢救已有数据——别误判为"索引损坏可完整修复"

# Skill 优先原则

- **有专门 Skill 可用时，必须优先调用 Skill，不要因为"觉得自己能搞定"就绕过**。Skill 封装了专门的流程和质量保障（如 `skill-creator:skill-creator` 用于创建 skill，`superpowers:writing-plans` 用于写计划），跳过它等于放弃专门工具的价值。即使当前上下文已经充足，Skill 的流程本身也是一层额外的质量检查。
- **默认语义：用户提“改 skill”=改项目源码**。在本会话语境中，默认指向 `~/Documents/agent-steroids`（或其对应工作树）里的源文件，不是 `~/.codex/plugins/cache/...` 中的副本。

# Skill 编写规则

- **Skill 不能有外部依赖**：Skill 文档（SKILL.md 及其引用的子文档）中不能引用 Skill 目录外的文件路径（如 `docs/`、`data/`、`sql/` 等）。Skill 是自包含的方法论，不依赖项目中的具体文件。如果需要提示"参考已有样本"，用搜索指引（如"在项目中搜索 xxx"）代替硬编码路径。
- **Skill 写方向不写步骤**：方法论文档重点说明**意图和方向**（为什么要这么做、典型模板有哪些），而非详细的操作步骤。用 2-3 个典型示例启发 agent 理解目标，而不是写 step-by-step 教程。Agent 是有判断力的，给方向比给步骤更有效。
- **Skill 要写成通用的**：不要引用个人特有的工具链或配置（如 `agents.json`、`yadm bootstrap`、特定 tmux session 名），而是用通用描述。Skill 面向所有用户，不是只给自己用的备忘录。
- **SKILL.md 和 CLAUDE.md 不超过 200 行**：超过则指令被稀释。精炼表述，详细流程拆到 `references/` 且必须被主文档引用。

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

**禁止自行启动 Chrome 实例。** 所有 agent 共用一个干净的共享 Chrome（`~/.config/cdp-chrome/`），通过 `mcp__cdp-chrome__*` 工具或直连 CDP API 操作。

# 代理配置

- 通过 `~/.env` 中的 `PROXY=on` 控制代理开关
- `~/.zshrc` 读取 `PROXY` 变量，当值为 `on` 时 export HTTP/SOCKS5 代理环境变量（`http_proxy`, `all_proxy` 等），地址为 `127.0.0.1:7890`
- SSH 代理（`~/.ssh/config`）通过 `ProxyCommand` 检测 `$all_proxy` 是否存在来决定是否走 SOCKS5 代理，不硬编码地址
- 远程机器下载海外资源慢时，优先用 SSH reverse tunnel 让远端复用本地代理；必须同时验证远端 `curl -x` 能访问目标源、本地 Clash controller 能看到连接命中预期节点。若确认走代理仍慢，再切换节点测速
- 关闭代理：在 `~/.env` 中删除或注释 `PROXY=on`，然后重启 shell

## 代理对大块 git over HTTPS 传输会截断（重要）

- **现象**：`brew`（尤其 `brew update` 的 tap git fetch）、大体积 `git fetch` / `git ls-remote https://github.com/...` 走 Clash 代理时会卡住几十秒后失败，典型报错 `RPC failed; curl 18 transfer closed with outstanding read data remaining`。节点对大块 git-over-HTTPS 传输会截断。诊断实测：`git ls-remote homebrew-core` 走代理 40s 超时截断，直连 27s 成功。
- **不是"没用上代理"**：代理是用上了，是节点扛不住大 git 传输。bottle/普通 HTTPS 小请求（ghcr.io 等）走代理是快的（~3s），不受影响。
- **修复**：
  - `brew`：用 `HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade <pkg>` 跳过最慢的 tap git fetch；bottle 下载照常走代理。
  - 一般 git：优先用 SSH 远程（`git@github.com:...`，SSH 走代理 OK，push/fetch 都正常）而非 HTTPS；或对该次操作临时 `env -u http_proxy -u https_proxy -u all_proxy ...` 直连（国内直连 GitHub 有时反而比这个节点稳）。

# Clash Verge 自建节点

- 模板：`~/.config/clash-verge/Script.js.tpl`，通过 `yadm bootstrap` 用 `~/.env` 变量替换占位符生成 `Script.js`
- 两个节点通过 `url-test` 组 `🏠 LA` 自动选延迟最低的：
  - `🏠 LA-Direct`：VLESS+Reality+Vision，直连 VPS（移动数据好用，天津电信拥塞不可用）
  - `🏠 LA-CDN`：VLESS+WS+TLS，经 Cloudflare CDN（域名 `kanlac.store`，电信宽带用）
- `~/.env` 中 `LISA_CDN_SERVER` 控制 CDN 节点连接地址（域名或优选 IP），`LISA_CDN_DOMAIN` 始终为域名（用于 SNI/Host）
- 修改模板后需运行 `yadm bootstrap` 重新生成；Clash Verge 最终应用/重载配置需要用户手动操作

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

# 法律 LLM-Wiki 仓库（lawyer-*）

法律案件知识编译系统，多仓库协作，均在 `~/Documents/` 下：
- `lawyer-shared`：共享的 law-wiki 插件/skill（编译方法论）+ prod-profile，跨案件复用
- `lawyer-dev`：系统配置（SPEC.yaml、governor、schema、文书模板），主开发仓
- `lawyer-case-qianshou`：单个案件的 Wiki vault（raw 材料 + 编译出的 wiki/）
- `lawyer-wls-ingest`：材料导入/拆分 pipeline（doc-split、SCHEMA.md）

# 计划文档编写规则

- **闭环**：计划必须从开始执行到最终验证形成完整闭环。不能停在"更新完配置"就结束——必须包含端到端测试、数据校验等步骤，确保改动真正生效
- **每个 Phase 有验证**：每个阶段结束时必须有可执行的验证步骤（命令、脚本、SQL 查询），不能只写"检查是否正确"
- **标注人工确认节点**：需要用户决策的节点用醒目标记（如 🔵），并明确说明需要用户确认什么。其余 Phase 默认自主执行，尽量减少用户介入

# 全局一致性（品位要求）

- **改了一处，就要保证全局一致**：一旦决定修改某个标准、字段、命名、设计或事实陈述，必须主动扫描整个仓库，把所有受影响、明显不一致的地方一并改成最新标准，不要只改触发点而留下散落的旧表述（例如：把交互组件改成静态后，文档里"可交互/点选"的描述也要同步改）。
- **自主修，不要过问**：发现这种明显的不一致时，直接按最新标准统一，不需要先征求确认。这是基本的品位要求——半途而废的、自相矛盾的产出比不改更糟。
- **边界**：仅适用于"已经决定的改动所引发的明显不一致"。对仍未拍板的开放决策（如待定的报价口径、两套并存的方案），不要自行统一，先呈现给用户。

# 文档和代码规范

- **不要在文档/代码中硬编码用户名**：Skill 文档、脚本、配置示例中使用 `$HOME`、`~`、`$USER` 等变量或占位符，不要出现具体的用户名（如 `/Users/kan/`）
- **文档命名规范**：所有文档统一使用 `yyMMdd-` 作为前缀命名（例如 `docs/260603-user-journey.md`），以保持跨项目的时间线清晰可回溯。
- **密集表格必须先定列宽再验证截图**：仪表盘、管理页、清单页等包含长文本列的 UI，不能依赖浏览器自动表格布局；必须先定义列优先级、固定/最小列宽和长文本处理策略，保证描述、路径、代码、JSON 等长文本列在目标视口可读，低价值字段应压缩、截断或移入详情/导出，并用实际截图验证桌面与窄屏视口不存在挤压、重叠或不可读列。

# macOS 通知横幅关闭

- 用 AppleScript 遍历 `NotificationCenter` 进程的所有 group 元素并 click，可触发"点击通知"效果使横幅消失（等同于用户手动点击，会同时打开对应 app）

# 文档查询

- **不要用 Context7 MCP 查 Claude Code 文档**：Context7 的索引有滞后，查不到新版本的字段和功能。查 Claude Code 最新文档用 `defuddle parse "https://docs.anthropic.com/en/docs/claude-code/<page>" --md` 直接抓官网

- **调研具体项目/仓库时：该 fetch 就别 search**（亲历：把短名 `qmd` 默认解析成最高频的 Quarto，又拿 WebSearch 二手摘要当结论）：
  - 用户给了 URL 或点名了具体项目，**直接 WebFetch 那个 URL**，不要 WebSearch 同名词。
  - 短名有歧义时先确认是哪个仓库（问用户 / 抓 `owner/repo`），别默选最有名的同名项目。
  - 下"它支持/不支持 X"这种结论前，先 fetch 一手 README，不信 WebSearch 摘要。


# NotebookLM 交互

需要和 NotebookLM 交互时，优先使用已配置好的 `notebooklm-py` CLI：进入 `$HOME/Documents/Codex/2026-05-25/teng-lin-notebooklm-py-https-github` 后运行 `uv run notebooklm ...`；上游仓库是 https://github.com/teng-lin/notebooklm-py，可用于排查问题或获取更新；认证已保存在 `~/.notebooklm/profiles/default/storage_state.json`，开始前可用 `uv run notebooklm auth check --test --json` 验证，不要重新索要 Google 账号密码。

# Telegram Channel 交互

- 收到 Telegram 消息后，先对该消息发送一个 👀 emoji react，表示正在处理，然后再开始实际工作
- **当会话接入了 Telegram channel 时，所有回复都通过 Telegram reply 工具发送，不在终端输出回复内容**。终端只用于执行工具调用（查数据库、读文件等），最终结果回复到 Telegram
- **Telegram 文件上传失败时**：Telegram plugin 的文件发送在 proxy 环境下会失败（Bun TLS bug，详见 `steroids:telegram-agents` Skill 的「Bun Proxy 文件上传问题」章节）。遇到 `Network request for 'sendDocument' failed!` 时，用 curl 直接调 Bot API 绕过：从状态目录的 `.env` 读 bot token，然后 `curl -X POST "https://api.telegram.org/bot$TOKEN/sendDocument" -F chat_id=<id> -F "document=@<path>"`

## Telegram 回复排版（MarkdownV2）

调用 Telegram `reply` / `edit_message` 工具时**必须显式传 `format: "markdownv2"`**。不传等同于 `"text"`，会丢失所有格式；只有 log dump、错误堆栈、原始命令输出等无格式化需求的内容才显式传 `format: "text"`。

**18 个特殊字符必须反斜杠转义**（漏一个就会 `Bad Request: can't parse entities` 整条消息失败）：

`_` `*` `[` `]` `(` `)` `~` `` ` `` `>` `#` `+` `-` `=` `|` `{` `}` `.` `!`

最常漏的四类场景：
- **日期 / 版本号**：`2026-04-07` → `2026\-04\-07`，`v1.2.3` → `v1\.2\.3`
- **域名 / 文件路径**：`example.com` → `example\.com`，`src/index.ts` → `src/index\.ts`
- **英文句尾标点**：`Done.` → `Done\.`，`真的!` → `真的\!`（中文句号不用转义）
- **行首连字符/井号/大于号**：`- 项目` → `\- 项目`（行首会被解析为列表/引用语法）

三个例外区（原样输出，**不**转义 18 字符）：
- **格式化标记本身**：`*粗体*`、`_斜体_`、`||剧透||`、`~删除线~` 的成对标记
- **行内代码 `` `code` `` 和代码块 ` ``` ` 内部**：只转义 `` ` `` 和 `\`，其他字符原样。含复杂符号的片段（正则、JSON、SQL）优先用代码块包裹
- **Markdown link 的 URL 部分**：`[文字](url)` 里 url 只转义 `)` 和 `\`，URL 自带的 `.` `-` `?` `=` `&` 不转义。例：`[文档](https://example.com/path?a=1&b=2)` 原样发送

**发送前自检**：组装好文本、调用工具**之前**扫一遍——`format` 参数有没有？18 字符除了例外区是否全转义？行首特殊字符是否转义？英文句点/叹号是否转义？

**兜底**：不确定的片段用行内代码 `` ` `` 包住；仍无把握就退回 `format: "text"` 发送纯文本——宁可丢格式，不要让消息发送失败。

**`can't parse entities` 报错时**：立刻用 `edit_message` 或重发 `format: "text"` 纯文本让用户先看到内容，再定位漏转义字符（错误里有 offset 提示）、修好后发 MarkdownV2 版。不要反复试错。

# Obsidian 库

- 路径：`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian/`
- 通过 iCloud 跨设备同步，私密文档（基础设施 SOP、账号信息等）放这里而非 memory 或公开仓库
- 文档放 `docs/` 子目录
- 文件名即标题，文档内部不写一级标题（`# 标题`）
- 已发布/待发布的文章通过 `writing.base` 追踪（frontmatter `writing: true` 的笔记）

# 参考资料沉淀

- **LLM-Wiki (Andrej Karpathy 提出)**: 
  - 概念来源: [Karpathy LLM Wiki Gist](https://gist.github.com/karpathy/d4e414c12bb166cdab0eb2160cf1c0d4) (及相关社区实践)
  - 核心思想: 放弃传统的“每次重新检索阅读生文”的 RAG 模式，转向“持续累积和编译”模式。系统维护一个结构化、互相链接的 Markdown Wiki。用户上传资料（Ingest），AI 提取事实更新 Wiki；用户提问（Query），AI 基于 Wiki 回答并更新新知识；AI 后台自动整理（Lint）。这非常适合做多品牌代运营的知识沉淀，是目前基础形态的产品方向。
