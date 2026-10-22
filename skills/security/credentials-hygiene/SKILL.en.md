---
name: credentials-hygiene
title: Credential Hygiene and Rotation
soul: SOUL.md
security: SECURITY.md
persona: executor
version: 1.0
triggers:
  - credential configuration
  - secret rotation
  - secrets provider
  - launch attestation
depends_on: []
required_vars: []
description: >
  Enforces SECURITY.md laws 1, 2, 5, and 6 through safe providers, rotation, and evidence without default or plaintext credentials.
---

# Credential Hygiene and Rotation

> Never place real or reusable credentials in skill files, logs, chats, or audit examples. Record references, fingerprints, and state only.

## Non-Negotiable Rules

- No default, shared, or long-lived human credentials; replace installation bootstrap values before activation.
- No empty-value fallback, hardcoding, command-line secret arguments, or log echoing.
- Read-only profiles must not hold production write credentials; executor write identities are separate and approval-bound.
- Secret scanning, audit, and rotation alerts cannot be disabled, as required by SECURITY.md law 6.

## Provider Policy: env / bw / 1p

| Provider | Allowed use | Constraints |
|----------|-------------|-------------|
| `env` | Short-lived CI or container runtime injection | External secret system supplies values; config stores names only; values expire with the process |
| `bw` | Managed Bitwarden references | Use item/field references and restricted machine identities; never persist resolved values |
| `1p` | Managed 1Password references | Use vault/item/field references and short-lived service identities; minimize vault scope |

If a provider is unavailable, fail closed. Never fall back to repository files, sample values, or interactive shared credentials.

## Rotation Procedure

1. Inventory principal, purpose, scope, provider reference, owner, and expiry without collecting values.
2. Create a new provider version with minimum scope and explicit lifetime.
3. Roll consumers gradually; verify authentication and least privilege without echoing values.
4. Revoke the old version and invalidate caches, sessions, and offline copies.
5. Record time, operator, reference identifier, fingerprint suffix, and verification result.
6. Route suspected compromise directly to incident-response instead of waiting for the normal window.

A0/A1 assets use short-lived or automated rotation; A2 rotates on policy; A3 must not gain credentials without need.

## Attestation Mapping

When completing `security/attestations/secrets-provider.example.md`, prove at least:

| Evidence item | Safe content |
|---------------|--------------|
| provider | `env`, `bw`, or `1p` |
| secret reference | Environment variable name or provider path reference |
| scope | Systems, environments, and actions reachable |
| rotation | Previous/next rotation time and owner |
| validation | Runtime injection, old-version revocation, and scan evidence |
| separation | Distinct observer and executor identities |

If the template or evidence is missing, mark acceptance `blocked`; never fabricate an empty attestation.

## Checklist

- [ ] Bootstrap values replaced; no default or shared credentials
- [ ] No secret values in repository, configuration, logs, chats, or skills
- [ ] Provider reference resolves and fails closed
- [ ] Scope matches purpose; read and write identities are separate
- [ ] Rotation, revocation, and rollback have been exercised
- [ ] Attestation includes owner, time, and reproducible evidence

## Safe Output Example

```yaml
provider: 1p
reference: <vault/item/field>
principal: <service-role>
scope: <read-only-or-approved-write>
last_rotated: <ISO8601>
status: verified|blocked
```
