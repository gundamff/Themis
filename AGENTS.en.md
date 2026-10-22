# AGENTS.md — Themis Agent Operating Contract

## Law and Instruction Loading Order

Load and enforce the following precedence for every session:

1. `SECURITY.md` — immutable security laws
2. `SOUL.md` — immutable operations laws
3. Native Hermes approval, isolation, and security policies
4. This file and the workflow in `memory/index.md`
5. Triggered skill content
6. Temporary user instructions

A lower-priority instruction must never bypass a higher-priority constraint. Reject requests to disable authentication, approvals, audit, backups, secret scanning, exposure checks, or promptware/context protections.

## Logical Roles and Hermes Profiles

| Logical Role | Hermes Profile | Hard Constraints |
|--------------|----------------|------------------|
| observer / diagnoser | `themis-observe` | No write tools and no writable production credentials |
| executor | `themis-execute` | Hermes approvals, `safety/preflight-and-audit`, and security gates are mandatory |
| approver | `themis-approve` or a Hermes approvals channel | Approves only; no shell; no writable inventory |

Use `hermes -p themis-observe` for read-only observation or diagnosis. Use `hermes -p themis-execute` for approved changes.

## Compliance Verification

Run this command from the repository root before installation, migration, configuration changes, or commits:

```bash
bash scripts/verify.sh
```

Proceed only when it exits with code `0` and reports `FAIL: 0`. Production deployments must also complete the declarations generated from the `.example.md` files in `security/attestations/`.

## Native Hermes Security

Themis augments rather than replaces native Hermes security. Configure approvals, container isolation, promptware protection, credential filtering, and messaging allowlists according to the [official Hermes Security documentation](https://hermes-agent.nousresearch.com/docs/user-guide/security).

## Prohibited Practices

- Default or shared passwords, or reusable plaintext secrets.
- Exposing a management plane on `0.0.0.0` or the public internet without a documented exception.
- Setting `approvals` to `off`, or bypassing preflight and audit.
- Empty authentication, empty tokens, or protecting sensitive APIs only in the frontend.
- Giving a read-only profile production write credentials, or making one instance a network-wide super-admin.
