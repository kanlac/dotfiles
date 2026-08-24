# Dotfiles 管理
- 使用 [yadm](https://yadm.io) 管理个人配置文件，详见 `~/README.md`

# Tailscale 内网
- `hostname` 确认当前是哪台机器，再判断是否需要通过 Tailscale 主机名 `kans-mac-mini` SSH 过去

# artifacts 目录
- 说「artifacts 目录」时，指的是 Mac mini 上的 `/Users/Shared/artifacts`，对应公网地址 `https://artifacts.kanlac.store/<文件名>`。复制到该目录即可分享链接
- **这个目录公网无鉴权，任何人拿到 URL 都能访问**，文件名就是唯一的门槛。按内容敏感度选名字：
  - **含真实人名、报价底线、谈判条款、他人隐私的** —— 必须用不可猜的随机串，且不要把链接贴到任何公开场合
  - **本来就要发给别人看的成品**（服务说明、分享稿、给客户的页面）—— 可以用有含义的短名字，方便直接发链接

# 项目索引

| 项目 | 路径 | 用途 |
|---|---|---|
| finance | `~/finance` | 个人/家庭财务记录、计划、决策留痕。含金额等敏感数据，勿外传 |
| agent-steroids | `~/Documents/agent-steroids` | 共享的公开 Claude 插件。Skill 放 `skills/`、Command 放 `commands/`；个人专属 skill 放 `~/.claude/`，不放这里 |
| Obsidian 库 | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian/` | 私密文档 + 写作库，详见下方专节 |
| witness | `~/witness` | 个人目标系统，数据和代码同仓，详见下方专节 |

# 飞书 / Lark CLI
- 处理飞书 / Lark / Feishu 相关任务时，优先使用 `lark-cli`；执行具体操作前，先用 `lark-cli skills list` 判断领域，再用 `lark-cli skills read <skill-name>` 读取官方 skill 文档，不要凭记忆直接调用命令。常见入口：认证/权限读 `lark-shared`，文档读写读 `lark-doc`，云盘文件读 `lark-drive`，消息读 `lark-im`，日历读 `lark-calendar`；官方仓库：https://github.com/larksuite/cli

# Git SSH 配置
- 默认使用 `github.com`（例如 `git@github.com:user/repo.git`）

# Git 历史重写禁令
- **不要用 `git filter-branch`**：它会重写整棵 commit 树的 hash，导致分支与 master 断开共同祖先，GitHub 上无法正常 diff/PR。cherry-pick 重建分支时极易丢失文件（亲历：base.css 和 main.js 改动丢失，全站样式崩溃）
- **从历史中删文件的正确做法**：在新 commit 里 `git rm` + 加 `.gitignore`，不重写历史。如果确实需要清除敏感数据，用 `git filter-repo`（比 filter-branch 安全）
- **重建分支后必须验证**：如果不得已做了 cherry-pick 重建，必须检查关键文件（入口文件、配置文件、CSS 入口）是否完整，跑一遍 `git diff` 确认改动数量与预期一致

# Git Worktree 规范
- 所有 worktree 统一放在 `$WORKTREE_ROOT/<repo>/<name>`（`WORKTREE_ROOT` 默认 `~/worktrees`），按仓库分组，不再放仓库同级目录。
- 每个有 worktree 的仓库在 `$WORKTREE_ROOT/<repo>.code-workspace` 维护一个 VS Code 多根 workspace 文件（放 worktrees 目录、不进仓库），方便 Remote-SSH 到 `kans-mac-mini` 后直接打开。该文件由 `git worktree list` 自动生成，不手改。
- 用 `wt` 函数管理（定义在 `~/.config/zsh-custom/worktree.zsh`，oh-my-zsh 自动加载）：`wt add <name>` 创建、`wt rm <name>` 删除、`wt ls` 列出；主仓库或任一 worktree 内都能运行，创建/删除会自动重生成 workspace 文件。
- Claude Code 的 `isolation: "worktree"` 默认放在 `.claude/worktrees/`，与本规范不符；如需手动创建 worktree，用 `wt` 函数或按上述规范执行。

# GitHub 评论发布规则
- 需要在 GitHub issue/PR 上发布评论、回复维护者、解释问题或补充信息时，先把拟发布内容作为草稿发给用户确认；用户明确同意后再调用 GitHub/`gh` 写入。除非用户在当前消息中明确要求“直接发/帮我回复”，否则不要代发。

# 解压含中文文件名的 zip
- 别用 `unzip`/`ditto`（按 cp437 瞎解中文名）。用 Python `zipfile`，优先读条目的 `0x7075`（Info-ZIP Unicode Path）取真实 UTF-8 名，无该字段再按 GBK 兜底；跳过 `__MACOSX`、防 zip-slip。截断的 zip 只能 `zip -FF` 抢救已有数据，缺失部分救不回

# Skill 规则
- **用户说"改 skill" = 改项目源码**，默认指 `~/Documents/agent-steroids`（或其工作树）里的源文件，不是 `~/.claude/plugins/cache/...` 或 `~/.codex/plugins/cache/...` 的副本
- **Skill 不能有外部依赖**：不引用 Skill 目录外的路径。需要"参考已有样本"时用搜索指引代替硬编码路径
- **写方向，不写步骤**：说明意图和方向、给 2-3 个典型示例，而不是 step-by-step 教程。Agent 有判断力
- **SKILL.md 和 CLAUDE.md 不超过 200 行**，详细流程拆到 `references/` 并被主文档引用

# Chrome 浏览器自动化
- 需要有头 GUI Chrome 时（社交媒体、登录态、反爬、截图、表单），**必须先 invoke `chrome:cdp-chrome` Skill** 并遵循其规则；读社交媒体内容直接用它，别先试 WebFetch/defuddle
- **禁止自行启动 Chrome 实例**，所有 agent 共用 `~/.config/cdp-chrome/` 那个共享实例
- **遇到登录页先别下「未登录」结论**：很多站（如 Cloudflare）的登录页其实是账户选择器，点击页面上显示的默认账户往往直接进入——先试这一下，再报告需要用户登录

# 代理配置
- 通过 `~/.env` 中的 `PROXY=on` 控制代理开关
- `~/.zshrc` 读取 `PROXY` 变量，当值为 `on` 时 export HTTP/SOCKS5 代理环境变量（`http_proxy`, `all_proxy` 等），地址为 `127.0.0.1:7890`
- SSH 代理（`~/.ssh/config`）通过 `ProxyCommand` 检测 `$all_proxy` 是否存在来决定是否走 SOCKS5 代理，不硬编码地址
- 远程机器下载海外资源慢时，优先用 SSH reverse tunnel 让远端复用本地代理；必须同时验证远端 `curl -x` 能访问目标源、本地 Clash controller 能看到连接命中预期节点。若确认走代理仍慢，再切换节点测速
- 关闭代理：在 `~/.env` 中删除或注释 `PROXY=on`，然后重启 shell
- **大块 git-over-HTTPS 走代理会被节点截断**（`brew update` 的 tap fetch、大 `git fetch`/`ls-remote`，报 `curl 18 transfer closed`）。不是没走代理，是节点扛不住。改用 SSH 远程，或该次操作临时 `env -u http_proxy -u https_proxy -u all_proxy` 直连；brew 加 `HOMEBREW_NO_AUTO_UPDATE=1`

# 跨 Agent 共享（Claude Code / Codex CLI）

让项目记忆和 skill 在 Claude Code 与 Codex CLI 之间共用，避免两份漂移：

- **新建项目 AGENTS.md 时，必须同时建一个 CLAUDE.md 与它互为 symlink**（谁是真身都行，方向不限，但 symlink 必须存在），保证两个 agent 读到同一份项目记忆。
- **Skill 通过目录级 symlink 共享**：让 `.claude/skills` 与 `.codex/skills` 指向同一目录（保留 `.claude/skills` 为真身，`ln -s ../.claude/skills .codex/skills`），两边看到同一套项目级 skill。

# 派活给外部模型

**Codex**：

```bash
codex exec --sandbox danger-full-access --model gpt-5.6-sol \
  -c model_reasoning_effort=xhigh --skip-git-repo-check \
  -o result.md "$(cat prompt.txt)" < /dev/null
```

- `< /dev/null` 不能省，否则卡在 `Reading additional input from stdin...` 一动不动。
- 后台走 Bash 工具的 `run_in_background`，末尾不加 `&`；加了就成了不受追踪的孤儿进程，跑完没有通知。
- 沙箱禁网：先替它装好依赖，提示词里禁止联网命令、缺包只许报包名。
- 两个 Codex 不同时写一个仓库；只读/调研类放仓库外跑。
- **用 Codex 生图**：Codex CLI 内置 GPT Image 2，prompt 里直接说「Generate an image and save to /path/to/file.png」，它会调用内置的 image generation tool 生成图片。**不要让 Codex 写 Python 代码调 OpenAI SDK**（环境里没有 OPENAI_API_KEY，会失败）。Codex 走 ChatGPT Plus OAuth，内置能力不需要额外 key。

**OpenCode** —— provider 固定 `ark-coding`（火山 Coding Plan），`opencode run -m ark-coding/<model>`，`opencode models ark-coding` 列全部：

- 主力 `glm-5.3`；要长输出（整文件重写、大批量生成）换 `deepseek-v4-pro`，393K 输出上限是唯一扛得住的。
- 截至 2026-08-19 实测没有 Kimi K3，之后可能上新，以 `opencode models` 为准。

# 全局一致性（品位要求）

- **改了一处，就要保证全局一致**：一旦决定修改某个标准、字段、命名、设计或事实陈述，必须主动扫描整个仓库，把所有受影响、明显不一致的地方一并改成最新标准，不要只改触发点而留下散落的旧表述（例如：把交互组件改成静态后，文档里"可交互/点选"的描述也要同步改）。
- **自主修，不要过问**：发现这种明显的不一致时，直接按最新标准统一，不需要先征求确认。这是基本的品位要求——半途而废的、自相矛盾的产出比不改更糟。
- **边界**：仅适用于"已经决定的改动所引发的明显不一致"。对仍未拍板的开放决策（如待定的报价口径、两套并存的方案），不要自行统一，先呈现给用户。

# 文档和代码规范

- **不要在文档/代码中硬编码用户名**：Skill 文档、脚本、配置示例中使用 `$HOME`、`~`、`$USER` 等变量或占位符，不要出现具体的用户名（如 `/Users/kan/`）
- **文档命名规范**：所有文档统一使用 `yyMMdd-` 作为前缀命名（例如 `docs/260603-user-journey.md`），以保持跨项目的时间线清晰可回溯。
- **CLAUDE.md / AGENTS.md 只写上层引导，不写具体做法**：说明数据在哪、用哪个工具、以及推不出来的关键事实，不要贴命令、SQL 或分步教程。模型有能力自己查出具体怎么做，写细只会让文件腐化。

# 制品文案自检：先坐到用户那把椅子上

做「制品」——交付给用户使用或观看的成品，如 HTML 页面、PDF、报告、幻灯片、界面——时，写任何用户会看到的文字之前，先做一次视角自检：说话人是「产品」，听话人是「用户」，说的是「用户的处境」。凡是在解说功能、点评机制、或对读者/自己旁白的句子，都不是产品在说话，删掉重写。类比只是皮，不能改变所指；风味和准确冲突时，准确优先。

固定的决定（措辞、结构、标准、设计）一次定死、固化成产物（模板/固定串/配置）复用；运行时只产出真正因情况而变的东西（数据）。每次重新生成一个本该固定的东西，就是又一次出错和漂移的机会。

# 文档查询

- **不要用 Context7 MCP 查 Claude Code 文档**：Context7 的索引有滞后，查不到新版本的字段和功能。查 Claude Code 最新文档用 `defuddle parse "https://docs.anthropic.com/en/docs/claude-code/<page>" --md` 直接抓官网

- **调研具体项目/仓库时：该 fetch 就别 search**（亲历：把短名 `qmd` 默认解析成最高频的 Quarto，又拿 WebSearch 二手摘要当结论）：
  - 用户给了 URL 或点名了具体项目，**直接 WebFetch 那个 URL**，不要 WebSearch 同名词。
  - 短名有歧义时先确认是哪个仓库（问用户 / 抓 `owner/repo`），别默选最有名的同名项目。
  - 下"它支持/不支持 X"这种结论前，先 fetch 一手 README，不信 WebSearch 摘要。

# Witness 个人目标系统

见证努力、维持计划一致性的系统：**Goal** 记目标，**Decision / LDR** 记不可变且只能被 supersede 的安排，**Evidence** 分别记努力（0–3）与信号（−3…+3），两者不相加。

- 记录或复盘时，主动读 Obsidian daily note 和用户口述，先讲出判断待用户确认后再落库；**Obsidian 始终只读**。
- 数据、代码和日常交互用的 `witness` skill 均在 `~/witness`；字段以 `SCHEMA.md` 为唯一权威。
- 与 `Habits.md`、`thread-*.md` 互相独立，不打通、不同步。

# Obsidian 库

- **未经明确指示，不要在 Obsidian 库里产出任何文件**。库是用户自己的手写空间，agent 默认只读不写。临时产物（HTML、报告、草稿等）一律放会话的 scratchpad 临时目录，随系统重启被清理掉；只有用户明确说「存到 Obsidian / 保存到库里」时才写入
- 通过 iCloud 跨设备同步，私密文档（基础设施 SOP、账号信息等）放这里而非 memory 或公开仓库
- 一般文档放 `docs/` 子目录，用 `yyMMdd-` 前缀命名
- 文件名即标题，文档内部不写一级标题（`# 标题`）

## 写作库（posts.base）

- 已发布/待发布的文章通过仓库根目录的 `posts.base` 追踪，base 过滤条件是 frontmatter `posts == true`
- **博客文章放 `posts/` 目录**，文件名即标题、不加 `yyMMdd-` 前缀
- **创建或编辑博客文章前必须先读 `posts/SCHEMA.md`**，frontmatter 字段、post_tags 封闭词表等以该文件为准，这里不再重复
- 正文不写一级标题；新建后会自动出现在 base 的 Table 视图（按 `publish-date` 倒序）
- `docs/thread-lawyer/`：律师所 AI 阅卷产品（与 Robin、刘海清律师合作）项目的**非开发**个人知识沉淀——角色定位、合同/股权、法律风险、谈判备忘等

# 参考资料沉淀

- **LLM-Wiki (Andrej Karpathy 提出)**: 
  - 概念来源: [Karpathy LLM Wiki Gist](https://gist.github.com/karpathy/d4e414c12bb166cdab0eb2160cf1c0d4) (及相关社区实践)
  - 核心思想: 放弃传统的“每次重新检索阅读生文”的 RAG 模式，转向“持续累积和编译”模式。系统维护一个结构化、互相链接的 Markdown Wiki。用户上传资料（Ingest），AI 提取事实更新 Wiki；用户提问（Query），AI 基于 Wiki 回答并更新新知识；AI 后台自动整理（Lint）。这非常适合做多品牌代运营的知识沉淀，是目前基础形态的产品方向。
