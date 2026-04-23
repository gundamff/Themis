---
name: preflight-and-audit
title: High-Risk Operation Preflight Checks and Audit Log
soul: SOUL.md
persona: executor
version: 2.0
triggers:
  - 高危操作
  - 删除
  - 重启
  - 执行前检查
  - 审计日志
  - preflight
  - 操作审批
required_vars: []
description: >
  Implements the enforcement flow for the Three Laws defined in SOUL.md: preflight checks, blocking, and auditing.
  This skill contains only the execution mechanism. It does not repeat the law text; SOUL.md is the sole authoritative source for the laws.
---

# Preflight Checks and Audit

> This skill implements the execution flow for the Three Laws defined in SOUL.md.
> Any write operation by the executor persona must complete this skill's preflight process before proceeding.

## Trigger Conditions

This skill is automatically invoked before the executor persona performs any of the following:

- The operation description contains any keyword from `references/high_risk_keywords.txt`
- The operation target involves database writes, service restarts, file deletions, or configuration changes
- The operation is irreversible (cannot be restored from backup)

## Preflight Process (sequential; any step failure blocks execution)

### Step 1: Keyword Scan

Read `references/high_risk_keywords.txt` and match each line against the operation description (case-insensitive).

- **Match** → set `risk_level = high`, proceed to Step 2
- **No match** → set `risk_level = low/medium`, may skip to Step 4

### Step 2: Backup Verification

Confirm that the target data/service has a complete, usable backup within the last 24 hours.

Verification method:
```bash
# Check whether backup files exist and are within 24h
find /path/to/backup -name "*.gz" -mtime -1 | head -5
# Expected: at least 1 result
```

- `backup_verified = true`: proceed to Step 3
- `backup_verified = false`: **block execution**, output:
  ```
  [BLOCKED] No valid backup found (within 24h). Operation blocked.
  Please perform a backup first, then resubmit the operation request.
  trace_id: <uuid>
  ```

### Step 3: Human Approval Request

Generate a preflight report (see format below) and send it to the approver persona or notify the operations channel.

Wait for the `human_approved = true` signal before proceeding to Step 4.

**Hard-block scenarios (reject immediately, do not wait for approval):**
- The operation requests disabling the audit service
- The operation requests disabling the backup service
- The operation requests modifying SOUL.md

### Step 4: Generate Audit Log Entry

Invoke `scripts/audit_logger.py` (see below) to write to `audit_sink` (from config.yaml).

```bash
python3 skills/safety/preflight-and-audit/scripts/audit_logger.py \
  --operator "hermes/executor" \
  --action "operation description" \
  --target "target system" \
  --risk-level "high|medium|low" \
  --backup-verified true \
  --human-approved true \
  --result "executed" \
  --params '{}'
```

### Step 5: Execute and Record Result

After the operation completes, update the audit entry's `result` field to `executed|failed` and append a summary of the actual output.

---

## Preflight Report Format (sent to approver)

```markdown
## High-Risk Operation Approval Request

- **trace_id**: <uuid4>
- **Time**: <ISO8601>
- **Operator**: hermes/executor
- **Operation Description**: <specific operation>
- **Target System**: <IP/service name>
- **Risk Level**: high
- **Triggered Keyword**: <matched keyword>
- **Backup Verification**: ✓ Verified (most recent backup: <timestamp>)
- **Reversibility**: Irreversible / Reversible
- **Impact Scope**: <affected services/data>

The approver must respond within 30 minutes. Timeout is treated as rejection.
```

---

## Operation Blocking Rules

| Condition | Action |
|-----------|--------|
| Direct deletion of production data with no backup | Block immediately, do not submit for approval |
| Shutting down/disabling the backup service | Block immediately, do not submit for approval |
| Shutting down/disabling the audit service | Block immediately, do not submit for approval |
| Modifying SOUL.md | Block immediately, do not submit for approval |
| High-risk keyword match + backup available | Pause, submit to approver for approval |
| High-risk keyword match + no backup available | Block, require backup before resubmission |
| Large-scale operation during high load | Degrade: reduce concurrency, switch to read-only mode, notify observer |

---

## High-Risk Keyword List

See `references/high_risk_keywords.txt` (one keyword per line, regex supported).

---

## Audit Log Format

```json
{
  "trace_id": "<uuid4>",
  "timestamp": "<ISO8601>",
  "operator": "hermes/executor",
  "action": "<operation description>",
  "target": "<target system/resource>",
  "risk_level": "low | medium | high | critical",
  "backup_verified": true,
  "human_approved": true,
  "result": "executed | blocked | pending_approval | failed",
  "parameters": {},
  "signature": "<sha256 hash of serialized all fields>"
}
```

The log write path comes from `config.yaml → audit.sink`, defaulting to `/var/log/hermes/audit.jsonl`.
Each log entry is appended (append-only), never overwritten, never deleted.