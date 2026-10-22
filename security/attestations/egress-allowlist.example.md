# 声明：Agent 出站 Egress Allowlist

> 复制为 `egress-allowlist.<环境>.md`。用于打断 lethal trifecta（私有数据 + 不可信内容 + 任意外联）。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 范围: Hermes Agent 进程 / 其 `terminal.backend` 容器网桥 / 宿主机出站策略

## 控制摘要

| 控制 | 已落实 | 证据 |
|------|--------|------|
| 容器/主机默认拒绝出站，仅 allowlist 放行 | ☐ | `<防火墙/安全组/CNI 策略 ID>` |
| observe profile 已禁用 `browser`/`web` 等外联 toolset | ☐ | profile `config.yaml` 版本或哈希 |
| 生产未设置 `HERMES_YOLO_MODE=1` | ☐ | 配置审计 / `.env` 审查记录 |
| 允许目标仅含运维必需（制品库、内网 API、指定 LLM 网关等） | ☐ | allowlist 清单附件 |

## 备注

- 与 `SECURITY.md` §7、`AGENTS.md` Profile 安装要点及 `SEC-EGRESS` / `SEC-YOLO` 门禁对齐。
- 临时放行须有时限、审批与回滚；禁止「全开 443」作为生产默认。
