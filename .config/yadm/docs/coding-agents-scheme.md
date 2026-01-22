# Coding Agents 统一配置方案

管理 Claude Code 和 OpenCode 的 MCP Servers 及插件配置。

## 配置文件

**位置**: `~/.config/coding-agents.json`

```json
{
  "claude": {
    "mcpServers": { ... },
    "plugins": [ ... ]
  },
  "opencode": {
    "mcp": { ... }
  }
}
```

## 工作原理

`yadm bootstrap` 执行时：

1. **Claude MCP Servers** — 合并到 `~/.claude.json` 的 `mcpServers` 字段
2. **OpenCode MCP Servers** — 合并到 `~/.config/opencode/opencode.json` 的 `mcp` 字段
3. **Claude Plugins** — 自动执行 `claude plugins install`

## 格式说明

两个工具的 MCP 配置格式不同，所以分别存储：

### Claude 格式
```json
{
  "command": "npx",
  "args": ["@playwright/mcp@latest"],
  "type": "stdio"
}
```

### OpenCode 格式
```json
{
  "type": "local",
  "command": ["npx", "@playwright/mcp@latest"]
}
```

## 注意事项

- 本地特有的 MCP server（如带 auth state 的 playwright）不会被覆盖
- `~/.claude.json` 和 `opencode.json` 本身不由 yadm 跟踪（包含本地状态）
- 需要安装 `jq`：`brew install jq`
