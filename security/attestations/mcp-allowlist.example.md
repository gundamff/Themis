# 声明：生产 MCP 已按批准清单部署

> 复制为 `mcp-allowlist.<环境>.md`。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 清单版本/哈希: `<git rev or file hash of mcp-allowlist.yaml>`

## 检查项

| 项 | 期望 | 实际 |
|----|------|------|
| 仅清单内 server 已启用 | ☐ | |
| 版本钉死（无 `@latest`） | ☐ | |
| `allow_ad_hoc_install: false` | ☐ | |
| 自上次审查后无未重审的工具描述变更 | ☐ | |
| Hermes MCP credential filtering 已开 | ☐ | |

## 备注

- 与 `skills/security/mcp-supply-chain`、`security/mcp-allowlist.example.yaml`、`SEC-MCP` 对齐。
