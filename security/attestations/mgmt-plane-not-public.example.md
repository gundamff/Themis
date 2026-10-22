# 声明：管理面未对公网暴露

> 复制为 `mgmt-plane-not-public.<环境>.md`。例外暴露须书面批准 + IP allowlist + MFA。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 范围: 配置中心 / 消息集群 / 调度 UI / k8s dashboard / 堡垒 / Agent Gateway / 运维 API
- 结果: 上述管理入口默认仅内网或零信任通道可达；无未鉴权 `0.0.0.0` 监听
- 证据位置: `<防火墙/网关规则工单号或扫描报告编号>`

## 绑定与暴露摘要

| 服务类 | 绑定策略 | 公网可达 | 鉴权/MFA |
|--------|----------|----------|----------|
| Hermes API | `127.0.0.1` 或内网 LB | ☐ 否 | ☐ |
| 配置中心 UI | 内网/VPN | ☐ 否 | ☐ |
| k8s API/dashboard | 内网/VPN | ☐ 否 | ☐ |
| 堡垒 | 内网/VPN | ☐ 否 | ☐ |

## 备注

- 与 `skills/security/exposure-control` 及 `SEC-BIND` 门禁对齐。
- 任何临时公网映射须有时限、审批记录与回滚计划。
