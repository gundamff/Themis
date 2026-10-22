---
name: authz-baseline
title: Authentication and Authorization Baseline
soul: SOUL.md
security: SECURITY.md
persona: diagnoser
version: 1.0
triggers:
  - authorization baseline
  - sensitive endpoint review
  - empty authentication check
  - permission regression
depends_on: []
required_vars: []
description: >
  Enforces SECURITY.md laws 1, 3, and 5 by rejecting empty authentication and testing server-side least authorization.
---

# Authentication and Authorization Baseline

## Empty Authentication Is Forbidden

Management, data, and execution endpoints must verify identity and permission on the server. Block any case where:

- A missing, empty, malformed, or invalid token still returns sensitive data or performs an action.
- A default or anonymous principal gains management authority from network location alone.
- Authorization exists only as a hidden frontend control, route, or parameter.
- Authentication failure falls back to a privileged, shared, or debug identity.

Health endpoints expose minimal liveness only, not configuration, topology, detailed versions, or authentication state.

## Sensitive Endpoint Inventory

Cover at least these abstract classes:

| Class | Capability | Minimum authorization |
|-------|------------|-----------------------|
| Management | Users, roles, policy, system configuration | Separate admin permission plus MFA-equivalent auth |
| Data | Query, export, bulk read, backup/restore | Data-domain and environment scope; deny by default |
| Execution | Commands, jobs, deployment, restart, scaling | Approval-bound executor identity |
| Credentials | Create references, rotate, revoke | No plaintext read; complete audit |
| Audit | Query, export, retention policy | Read and administration separated; evidence cannot be deleted |

## Review Procedure

1. Build inventory from routes, API descriptions, message consumers, and management UI backends.
2. Label sensitivity, allowed principal, action, environment, tenant, and approval requirement.
3. Test missing, empty, invalid, expired, and wrong-audience identity material.
4. With a low-privilege principal, attempt reads, writes, cross-tenant, cross-environment, and bulk actions.
5. Verify enforcement on the server; direct backend calls cannot bypass it.
6. Confirm denial events include trace ID, principal summary, action, and reason without secret leakage.
7. Cross-sign results against SECURITY.md laws 1, 3, and 5 and the asset inventory.

Missing identity yields authentication failure; valid identity without permission yields authorization failure. Neither path may create side effects.

## Least-Authorization Model

```yaml
resource: <abstract-resource>
action: read|write|execute|admin
allowed_principals: [<role>]
environment: <scope>
tenant: <scope>
approval_required: true|false
default: deny
```

Observers use read-only profiles. Executor write access is time-, resource-, and approval-bound; no single instance receives domain-wide superuser authority.

## Regression Items

- [ ] Missing, empty, invalid, and expired identities fail
- [ ] Hidden frontend controls are not authorization evidence
- [ ] Low-privilege principals cannot write or cross scopes
- [ ] Bulk and single-resource endpoints apply identical policy
- [ ] New endpoints default deny and enter inventory
- [ ] Observer and executor identities remain separate
- [ ] Denials and approvals are auditable; controls cannot be silently disabled
