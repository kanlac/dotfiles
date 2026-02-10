# Git SSH 配置

- 默认使用 `github.com`（例如 `git@github.com:user/repo.git`）
- mindfit 项目使用 `mindfitgit` 作为 git SSH host

# 代理配置

- 通过 `~/.env` 中的 `PROXY=on` 控制代理开关
- `~/.zshrc` 读取 `PROXY` 变量，当值为 `on` 时 export HTTP/SOCKS5 代理环境变量（`http_proxy`, `all_proxy` 等），地址为 `127.0.0.1:7890`
- SSH 代理（`~/.ssh/config`）通过 `ProxyCommand` 检测 `$all_proxy` 是否存在来决定是否走 SOCKS5 代理，不硬编码地址
- 关闭代理：在 `~/.env` 中删除或注释 `PROXY=on`，然后重启 shell
