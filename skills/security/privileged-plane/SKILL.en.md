---
name: privileged-plane
title: Privileged Operations Plane Hardening
soul: SOUL.md
security: SECURITY.md
persona: executor
version: 1.0
triggers:
  - privileged plane hardening
  - configuration service review
  - k8s control plane
  - bastion review
depends_on: []
required_vars: []
description: >
  Hardens configuration, messaging, scheduling, k8s, and bastion planes under an assume-domain-takeover threat model.
---

# Privileged Operations Plane Hardening

## Core Assumption: One Plane Can Take the Domain

Configuration, messaging, scheduling, k8s control planes, and bastions are not ordinary backends. Assume compromise leads immediately to searches for domain credentials, bulk execution, and lateral movement.

The goal is not an obscure entry point. A single compromised plane must still face independent identity, network, authorization, approval, and audit boundaries.

## Common Hardening Baseline

- **Identity:** No default/shared identities; MFA-equivalent auth; short-lived service identity.
- **Secrets:** Provider references and runtime injection only; no reusable values in UI, config, or logs.
- **Network:** No public management plane; dedicated management network, source allowlist, minimal egress.
- **Authorization:** Default deny; observers read-only; executor writes time-, scope-, and approval-bound.
- **Audit:** Log login, policy change, secret action, and execution; controls cannot be silently disabled.
- **Resilience:** Back up configuration and audit evidence; rehearse isolation, revocation, and read-only degradation.

## Platform Hardening Checklists

### Configuration Service

- [ ] Separate namespaces and environments; approve production publication
- [ ] Store secret references only, never reusable secret values
- [ ] Separate read and publish rights; changes are traceable and reversible
- [ ] Client identities access only required namespaces

### Messaging

- [ ] Separate management API and data plane; reject anonymous access
- [ ] Authorize topics/queues per service; no wildcard administration
- [ ] Sign, deduplicate, and rate-limit high-impact messages
- [ ] Audit management actions and consumption anomalies

### Scheduling

- [ ] Authorize create, edit, immediate run, and backfill separately
- [ ] Job identity does not inherit scheduler administration
- [ ] Allowlist commands/parameters and redact sensitive output
- [ ] Bulk execution has approval, concurrency limits, and circuit breaker

### k8s Control Plane

- [ ] API and dashboard are private; anonymous access and wildcard RBAC are forbidden
- [ ] Minimize workload identity by namespace and service account
- [ ] High-privilege bindings are temporary, approved, and continuously audited
- [ ] Admission, audit, and secret scanning remain enabled

### Bastion

- [ ] Strong auth, device controls, personal accounts, session recording
- [ ] Role-grouped targets; no default domain-wide reachability
- [ ] File transfer, forwarding, and elevation require separate approval
- [ ] Revoke temporary credentials and residual sessions on exit

## Verify Domain Takeover Is Blocked

1. Select an abstract plane and assume its application identity is lost.
2. Enumerate readable secret references, reachable networks, and executable actions.
3. Verify it cannot cross environment/tenant boundaries or become infrastructure admin.
4. Verify high-impact actions still require independent identity and human approval.
5. Verify anomalies are detectable and can trigger an observe-only circuit breaker.

Any direct path to domain-wide control is `critical`; “internal network only” does not reduce it.

## Output

```yaml
plane: configuration|messaging|scheduler|k8s|bastion
compromise_assumption: application-identity-lost
reachable_scope: <abstract-scope>
domain_wide_control_blocked: true|false
evidence: [<control evidence>]
status: pass|blocked
```
