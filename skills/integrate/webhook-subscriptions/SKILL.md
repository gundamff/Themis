---
name: webhook-subscriptions
title: Webhook 事件订阅
soul: SOUL.md
persona: executor
version: 1.0
triggers:
  - webhook
  - 事件订阅
  - 自动触发
  - 外部通知
  - 告警触发
required_vars: []
description: 创建和管理 webhook 订阅，让外部系统（监控告警、CI/CD、IoT 平台等）自动触发 Agent 运行。
---

# Webhook 事件订阅

## 前置：启用 Webhook 平台

检查 webhook 状态：

```bash
hermes webhook list
```

若显示 "Webhook platform is not enabled"，执行：

```bash
hermes gateway setup
# 或手动在 config/config.yaml 中启用：
# platforms:
#   webhook:
#     enabled: true
#     host: "0.0.0.0"
#     port: 8644
#     secret: "${WEBHOOK_SECRET}"
```

启动网关：

```bash
hermes gateway run
# 或 systemd：
systemctl --user restart hermes-gateway
```

验证：

```bash
curl http://localhost:8644/health
# 期望：{"status": "ok"}
```

## 创建订阅

```bash
hermes webhook subscribe <名称> \
  --prompt "Prompt 模板，支持 {payload.字段名}" \
  --events "event1,event2" \
  --description "描述" \
  --skills "skill1,skill2" \
  --deliver <通知渠道> \
  --deliver-chat-id "<渠道 ID>"
```

## 常用场景

### 监控告警自动触发诊断

外部监控系统（任意能发 HTTP POST 的监控工具）触发后，Agent 自动执行诊断并推送结果：

```bash
hermes webhook subscribe ops-alert \
  --prompt "生产系统告警: {alert.name}\n严重级别: {alert.severity}\n详情: {alert.message}\n\n请立即诊断并给出处理建议。" \
  --skills "diagnose,observe" \
  --deliver <你的通知渠道> \
  --deliver-chat-id "${NOTIFY_CHAT_ID}"
```

Prompt 中 `{alert.name}` / `{alert.severity}` / `{alert.message}` 需要与你的监控工具发出的
webhook payload 字段名对应。在监控工具的 webhook 配置中，将 POST 目标设为订阅返回的 URL。

### 部署事件通知

CI/CD 流水线完成后自动通知，并可触发上线后的健康检查：

```bash
hermes webhook subscribe ci-deploy \
  --events "pipeline" \
  --prompt "部署事件: {status}\n项目: {project}\n分支: {branch}\n\n请执行上线后健康检查。" \
  --skills "observe" \
  --deliver <你的通知渠道> \
  --deliver-chat-id "${NOTIFY_CHAT_ID}"
```

字段名（`{status}` / `{project}` / `{branch}`）需要与你的 CI/CD 系统 payload 对应。

### 通用 Prompt 回调

任意外部系统都可以触发 Agent 执行特定 prompt，结果同步返回：

```bash
hermes webhook subscribe generic-trigger \
  --prompt "{prompt}" \
  --deliver origin
```

`--deliver origin` 表示结果同步返回给发起请求的调用方。

## 管理命令

```bash
hermes webhook list                                      # 列出所有订阅
hermes webhook remove <名称>                             # 删除订阅
hermes webhook test <名称>                               # 测试（不发送真实 payload）
hermes webhook test <名称> --payload '{"key":"val"}'     # 带 payload 测试
```

## Prompt 模板语法

使用 `{dot.notation}` 访问 payload 中的嵌套字段：

```
{alert.name}              → payload.alert.name
{alert.severity}          → payload.alert.severity
{data.object.amount}      → payload.data.object.amount
```

字段不存在时，模板中对应位置输出空字符串。

## 安全

- 每个订阅自动生成 HMAC-SHA256 密钥（或通过 `--secret` 指定）
- Webhook adapter 对每个 POST 请求验证签名，拒绝签名不匹配的请求
- `WEBHOOK_SECRET` 从 `config/secrets.env` 注入，不硬编码在配置文件中
- 订阅持久化到 `~/.hermes/webhook_subscriptions.json`

## 故障排查

```bash
# 网关是否在运行？
systemctl --user status hermes-gateway

# Webhook 服务是否监听？
curl http://localhost:8644/health

# 查看 webhook 日志
grep webhook ~/.hermes/logs/gateway.log | tail -20

# 签名不匹配？
hermes webhook list  # 确认 secret 与外部服务配置一致
```
