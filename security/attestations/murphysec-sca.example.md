# 声明：依赖/供应链 SCA（murphysec 或等效）

> 复制为 `murphysec-sca.<环境或周期>.md`。Themis **不内置** murphysec；本文件记录外部 SCA 证据。
> 覆盖：Agent 运行时依赖、MCP server 制品、自定义 skill 脚本依赖（若有 lockfile）。

- 范围: `<repo / image / mcp bundle>`
- 声明人: `<ROLE>`
- 周期: `<例如 2026-Q4>`
- 日期: `<ISO8601>`
- 工具与版本: `murphysec <ver>` 或等效

## 结果摘要

| 项 | 状态 | 证据 |
|----|------|------|
| Critical / High 未修复漏洞 | ☐ 无 / ☐ 有豁免工单 | |
| MCP 相关依赖已纳入扫描 | ☐ | |
| 与 `mcp-allowlist` 版本一致 | ☐ | |

## 备注

- 与 `skills/security/mcp-supply-chain`、`SEC-MCP` 对齐。
- 豁免须时限与负责人；禁止「永久忽略 Critical」。
