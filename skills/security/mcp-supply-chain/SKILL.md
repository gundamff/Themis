---
name: mcp-supply-chain
title: MCP 供应链控制
soul: SOUL.md
security: SECURITY.md
persona: diagnoser
version: 1.0
triggers:
  - MCP
  - 模型上下文协议
  - 工具服务器
  - MCP 供应链
depends_on: []
required_vars: []
description: >
  落实 MCP 批准清单、钉版本、禁临时安装与工具描述变更重审，降低供应链与描述投毒风险。
---

# MCP 供应链控制

> MCP server 可改变 Agent 可见工具与描述，等同供应链面。生产不得「会话里随手加一个」。

## 强制策略

1. **批准清单**：仅允许 `security/mcp-allowlist.yaml`（由 example 复制填写）中的 server。
2. **钉版本**：禁止 `@latest` 或浮动标签；记录 `version` 或 `integrity`（sha256）。
3. **禁临时安装**：`policy.allow_ad_hoc_install: false`；会话内 `mcp add` 未入清单 → 阻断。
4. **描述变更重审**：`require_redescribe_review: true`；工具 name/description/schema 变更须更新 `last_reviewed` 并经负责人确认。
5. **凭据过滤**：开启 Hermes MCP credential filtering；假定环境变量可被读走。

## 审查步骤

1. 导出当前启用的 MCP server 与版本。
2. 与批准清单逐项 diff；多余项立即禁用。
3. 对比上次审查的工具描述快照；有 diff 则进入重审，未完成不得用于生产 profile。
4. 确认无 `@latest`、无 ad-hoc。
5. 输出 `pass|blocked` 并保留证据（清单哈希、审查记录）。

## 输出

```yaml
mcp_servers_reviewed: <n>
allowlist_hash: <hash>
ad_hoc_forbidden: true
latest_forbidden: true
redescribe_pending: []
status: pass|blocked
```
