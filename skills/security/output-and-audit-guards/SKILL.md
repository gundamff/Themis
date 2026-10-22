---
name: output-and-audit-guards
title: 输出脱敏与工具审计护栏
soul: SOUL.md
security: SECURITY.md
persona: observer
version: 1.0
triggers:
  - 输出脱敏
  - 工具审计
  - 密钥回显
  - 外泄检测
depends_on: []
required_vars: []
description: >
  落实输出侧脱敏与 tool 调用审计最低字段，降低密钥回显与静默外泄风险。
---

# 输出脱敏与工具审计护栏

> 配置侧禁明文不够；对话回复与 tool 结果同样是泄密面。本 skill 定规程，不声称 Hermes 已内置过滤器。

## 输出护栏

- 禁止在回复、日志摘要、webhook 载荷中回显可复用密钥、长效 token、私钥材料。
- tool 结果入库或转发前脱敏：口令、Authorization、连接串等替换为 `[REDACTED]`。
- 警惕外泄模式：突然出现的外网 URL、大包 base64、未知 webhook；observe 应告警，execute 须有票据才可外发。
- 高危会话建议速率上限（每会话 tool 调用 / 外发次数）；超额降级为 observe-only。

## Tool 审计最低字段

每条 tool 事件对齐 `security/schemas/audit-tool-event.example.json`：

| 字段 | 要求 |
|------|------|
| `tool_name` | 必填 |
| `args_digest` | 对参数规范化哈希；禁止存明文密钥 |
| `outcome` | ok\|error\|blocked |
| `approval_ticket_id` | 高危写操作必填 |
| `trace_id` | 与 preflight 关联 |

## 异常指标（告警意向）

- 无有效票据的高危执行尝试
- 单位时间内高危命令次数超阈
- 审批绕过用语或要求 `approvals.mode=off`
- 异常 egress 目的地（对照 egress allowlist）

## 步骤

1. 确认 audit sink 可写且不可静默关闭。
2. 抽查近期 tool 事件是否含最低字段且无明文密钥。
3. 抽查 Agent 回复是否回显 secrets。
4. 输出 `pass|blocked` 与缺口清单。
