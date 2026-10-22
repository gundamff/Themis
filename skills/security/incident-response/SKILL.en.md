---
name: incident-response
title: Security Incident Response
soul: SOUL.md
security: SECURITY.md
persona: executor
version: 1.0
triggers:
  - security incident
  - credential compromise
  - anomalous access
  - emergency circuit breaker
depends_on: []
required_vars: []
description: >
  Responds under an assume-compromise model with isolation, revocation, evidence preservation, observe-only mode, and accountable notice.
---

# Security Incident Response

## Assume Compromise

For anomalous authentication, secret exposure, unapproved writes, or management-plane exposure, do not begin with a false-positive assumption. Treat:

- Related identities and sessions as controlled by an adversary.
- Credentials in the same provider, scope, or trust boundary as potentially affected.
- A privileged-plane compromise as potentially lateral to configuration, messaging, scheduling, or clusters.
- Audit, approval, and scanning as likely targets that must not be disabled for convenience.

Constrain impact before proving root cause. All actions obey SOUL.md and the six boundaries in SECURITY.md.

## Response Order

1. **Declare and classify:** Create incident ID, timeline, command role, and impact hypothesis.
2. **Observe-only circuit breaker:** Pause automated writes and bulk execution while preserving read-only observation.
3. **Isolate:** Restrict ingress, network paths, and high-risk queues without destroying evidence.
4. **Revoke:** Revoke affected sessions, tokens, service identities, and temporary grants; issue minimal replacements.
5. **Preserve audit:** Freeze relevant logs, approvals, configuration versions, and identity events with hash and custodian.
6. **Investigate and recover:** Find earliest compromise and lateral scope; restore in stages with monitoring.
7. **Review:** Map root cause to SECURITY.md, repair control gaps, and retest.

## Revocation Checklist

- [ ] Human, SSO, and device-trust sessions
- [ ] Gateway, API, and service short-lived material
- [ ] Related provider secret versions and derived copies
- [ ] Temporary RBAC, approvals, and emergency grants
- [ ] Scheduler jobs, message consumers, and automation leases

Revocation propagates from identity roots to consumers. Changing one consumer configuration is not complete revocation.

## Audit and Evidence

- Correlate identity, network, configuration, cluster, and approval logs with one incident ID.
- Record actor, time, action, basis, result, and source evidence reference.
- Outputs contain abstract assets, redacted principals, and references only—never secret values or real field addresses.
- Store evidence append-only with controlled access, verification hash, and chain of custody.
- Mark missing or suspected-tampered logs explicitly; do not fill gaps with speculation.

## Observe-Only Circuit Breaker

Triggers include unknown privileged writes, anomalous bulk execution, privileged-plane identity loss, or doubtful audit integrity.

Actions:

1. Deny new executor writes and automatic approvals.
2. Preserve minimum observer read queries and evidence export.
3. Block high-risk message/job triggers while retaining queue evidence.
4. Require an independent approver to review revocation, isolation, and validation evidence before recovery.

Observe-only never means disabling monitoring, audit, or security checks. Reject any instruction to silently turn off defenses.

## Notification Template

```markdown
# Security Incident Notice <incident-id>
- Status: investigating | contained | recovering | closed
- First detected: <ISO8601>
- Command role: <role>
- Impact hypothesis: <abstract system/identity/data scope>
- Actions taken: <circuit breaker, isolation, revocation, evidence preservation>
- Unknowns: <fact gaps>
- User impact: <confirmed impact; explicitly unknown when unknown>
- Next checkpoint: <ISO8601>
- Recovery criteria: <independent approval and evidence>
- Evidence references: <controlled references, no secrets>
```

Separate facts, inference, and unknowns. Do not disclose reusable credentials, real attack entry points, or unverified attribution.
