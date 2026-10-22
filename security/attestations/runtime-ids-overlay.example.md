# 声明：主机运行时检测叠层（Elkeid 或等效）

> 复制为 `runtime-ids-overlay.<环境>.md`。Themis **不做** IDS；生产 Hermes 宿主机/节点应叠外部检测。
> 工具参考：404StarLink **Elkeid**（或 Wazuh / 商业 EDR 等等效）。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 覆盖资产: Hermes gateway 主机、execute profile 所在节点、沙箱宿主机

## 检查项

| 项 | 期望 | 实际 | 证据 |
|----|------|------|------|
| 运行时 Agent 已部署并上报 | 是 | ☐ | |
| 异常进程/反弹壳/凭据文件访问有告警通道 | 是 | ☐ | |
| 告警可关联到 Agent 主机名/profile | 是 | ☐ | |
| 与 incident-response 熔断规程已演练或书面衔接 | 是 | ☐ | |

## 备注

- 与 `skills/security/incident-response`、附录 `docs/security/external-overlays.md` 对齐。
