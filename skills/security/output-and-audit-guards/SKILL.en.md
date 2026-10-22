---
name: output-and-audit-guards
title: Output Redaction and Tool Audit Guards
soul: SOUL.md
security: SECURITY.md
persona: observer
version: 1.0
triggers:
  - output redaction
  - tool audit
  - secret echo
  - exfiltration detection
depends_on: []
required_vars: []
description: >
  Defines output-side redaction and minimum tool-audit fields to reduce secret echo and silent exfiltration.
---

# Output Redaction and Tool Audit Guards

> Banning plaintext in config is not enough; chat replies and tool results leak too. This skill is procedural — it does not claim Hermes ships a built-in output filter.

## Output Guards

- Never echo reusable secrets, long-lived tokens, or private key material in replies, log summaries, or webhook payloads.
- Redact tool results before persist/forward: passwords, Authorization headers, connection strings → `[REDACTED]`.
- Watch exfiltration patterns: sudden external URLs, large base64 blobs, unknown webhooks; observe alerts; execute needs a ticket to send outbound.
- Prefer per-session rate limits on tool calls / outbound; exceed → observe-only.

## Minimum Tool Audit Fields

Align with `security/schemas/audit-tool-event.example.json`:

| Field | Requirement |
|-------|-------------|
| `tool_name` | required |
| `args_digest` | hash of canonical args; never store raw secrets |
| `outcome` | ok\|error\|blocked |
| `approval_ticket_id` | required for high-risk writes |
| `trace_id` | correlate with preflight |

## Anomaly Signals

- High-risk execution attempts without a valid ticket
- High-risk command rate above threshold
- Approval-bypass language or requests for `approvals.mode=off`
- Abnormal egress destinations vs allowlist

## Steps

1. Confirm audit sink is writable and cannot be silently disabled.
2. Sample recent tool events for minimum fields and no plaintext secrets.
3. Sample Agent replies for secret echo.
4. Emit `pass|blocked` with gaps.
