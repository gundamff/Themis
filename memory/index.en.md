# memory/index.en.md — Skills Index
# The Agent loads this file every session to quickly locate skills.
# When trigger words match, the corresponding skill is loaded automatically.

## How to Read This Index

- Each row format: `trigger keyword → skill path`
- The Agent fuzzy-matches user input; on match, it loads the corresponding SKILL.md
- A single request may trigger multiple skills (intersection, persona permission constraints take priority)

---

## Safety & Audit

| Trigger Words | Skill |
|---------------|-------|
| high-risk operation, delete, restart, preflight check, audit log, preflight, operation approval | `skills/safety/preflight-and-audit` |

---

## Infrastructure

| Trigger Words | Skill |
|---------------|-------|
| machine inventory, server list, host info, view nodes, inventory, hosts | `skills/infra/inventory-loader` |
| credentials, password, connection info, credentials, secrets | `skills/infra/credentials` |

---

## System Observability (observer)

| Trigger Words | Skill |
|---------------|-------|
| observe, monitor, inspection, health check, alert, system status, observe, health check, monitoring, change awareness | `skills/observe` |

---

## Fault Diagnosis (diagnoser)

| Trigger Words | Skill |
|---------------|-------|
| diagnose, fault, troubleshoot, root cause analysis, issue localization, diagnose, fault diagnosis, root cause, impact assessment, scene preservation, change correlation, timeline, evidence screening, postmortem, incident response | `skills/diagnose` |

---

## Data Backup (executor, requires preflight approval)

| Trigger Words | Skill |
|---------------|-------|
| backup, data backup, backup strategy, backup verification, backup recovery, backup | `skills/backup` |

---

## Integration & Automation (executor)

| Trigger Words | Skill |
|---------------|-------|
| webhook, event subscription, auto trigger, external notification, alert trigger | `skills/integrate/webhook-subscriptions` |

---

## SOUL.md (Three Laws, always loaded, not controlled by this index)

Always loaded, highest priority, not governed by the trigger word mechanism.

---

## Local Extension Skills

If you write local skills for a specific system, append trigger word mappings here:

```
| your trigger words | local skill path |
```