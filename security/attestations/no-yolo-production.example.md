# 声明：生产未启用 YOLO / 未关闭审批

> 复制为 `no-yolo-production.<环境>.md`。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`

## 检查项

| 项 | 期望 | 实际 | 证据 |
|----|------|------|------|
| `HERMES_YOLO_MODE` | 未设置或非 `1` | ☐ | |
| `approvals.mode` | `smart` 或 `manual`（非 `off`） | ☐ | |
| `GATEWAY_ALLOW_ALL_USERS` | 非 `true`；已配置 allowlist | ☐ | |
| `approvals.deny` | 含破坏性命令硬否决 | ☐ | |

## 备注

- 与 `SECURITY.md` §6、Hermes Security（YOLO 仍受 `approvals.deny` 约束）对齐。
- 开发机临时 YOLO 不得复用到生产 profile。
