---
name: webhook-subscriptions
title: Webhook Subscription Integration
soul: SOUL.md
persona: executor
version: 1.0
triggers:
  - webhook
  - event subscription
  - auto trigger
  - external notification
  - alert trigger
required_vars: []
description: Create and manage webhook subscriptions, allowing external systems (monitoring alerts, CI/CD, IoT platforms, etc.) to automatically trigger Agent runs.
---

# Webhook Subscription Integration

## Prerequisite: Enable the Webhook Platform

Check webhook status:

```bash
hermes webhook list
```

If it shows "Webhook platform is not enabled", run:

```bash
hermes gateway setup
# Or manually enable in config/config.yaml:
# platforms:
#   webhook:
#     enabled: true
#     host: "0.0.0.0"
#     port: 8644
#     secret: "${WEBHOOK_SECRET}"
```

Start the gateway:

```bash
hermes gateway run
# Or via systemd:
systemctl --user restart hermes-gateway
```

Verify:

```bash
curl http://localhost:8644/health
# Expected: {"status": "ok"}
```

## Create a Subscription

```bash
hermes webhook subscribe <name> \
  --prompt "Prompt template, supports {payload.field_name}" \
  --events "event1,event2" \
  --description "Description" \
  --skills "skill1,skill2" \
  --deliver <notification_channel> \
  --deliver-chat-id "<channel_id>"
```

## Common Scenarios

### Monitoring Alert Auto-Triggered Diagnostics

When an external monitoring system (any monitoring tool that can send HTTP POST) triggers an alert, the Agent automatically runs diagnostics and pushes the results:

```bash
hermes webhook subscribe ops-alert \
  --prompt "Production system alert: {alert.name}\nSeverity: {alert.severity}\nDetails: {alert.message}\n\nDiagnose immediately and provide remediation advice." \
  --skills "diagnose,observe" \
  --deliver <your_notification_channel> \
  --deliver-chat-id "${NOTIFY_CHAT_ID}"
```

The `{alert.name}` / `{alert.severity}` / `{alert.message}` in the prompt must match the webhook payload field names sent by your monitoring tool. In your monitoring tool's webhook configuration, set the POST target to the URL returned by the subscription.

### Deployment Event Notifications

Automatically notify when a CI/CD pipeline completes, and optionally trigger a post-deployment health check:

```bash
hermes webhook subscribe ci-deploy \
  --events "pipeline" \
  --prompt "Deployment event: {status}\nProject: {project}\nBranch: {branch}\n\nRun a post-deployment health check." \
  --skills "observe" \
  --deliver <your_notification_channel> \
  --deliver-chat-id "${NOTIFY_CHAT_ID}"
```

The field names (`{status}` / `{project}` / `{branch}`) must match your CI/CD system's payload.

### Generic Prompt Callback

Any external system can trigger the Agent to execute a specific prompt, with results returned synchronously:

```bash
hermes webhook subscribe generic-trigger \
  --prompt "{prompt}" \
  --deliver origin
```

`--deliver origin` means the result is returned synchronously to the calling system.

## Management Commands

```bash
hermes webhook list                                      # List all subscriptions
hermes webhook remove <name>                             # Delete a subscription
hermes webhook test <name>                               # Test (without sending a real payload)
hermes webhook test <name> --payload '{"key":"val"}'     # Test with a payload
```

## Prompt Template Syntax

Use `{dot.notation}` to access nested fields in the payload:

```
{alert.name}              → payload.alert.name
{alert.severity}          → payload.alert.severity
{data.object.amount}      → payload.data.object.amount
```

When a field does not exist, the corresponding placeholder outputs an empty string.

## Security

- Each subscription auto-generates an HMAC-SHA256 secret key (or specify one via `--secret`)
- The webhook adapter verifies the signature on every POST request, rejecting requests with mismatched signatures
- `WEBHOOK_SECRET` is injected from `config/secrets.env`, never hardcoded in config files
- Subscriptions are persisted to `~/.hermes/webhook_subscriptions.json`

## Troubleshooting

```bash
# Is the gateway running?
systemctl --user status hermes-gateway

# Is the webhook service listening?
curl http://localhost:8644/health

# Check webhook logs
grep webhook ~/.hermes/logs/gateway.log | tail -20

# Signature mismatch?
hermes webhook list  # Confirm the secret matches the external service configuration
```