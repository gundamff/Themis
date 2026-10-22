---
name: credentials
title: Credential Management Specification
soul: SOUL.md
persona: executor
version: 1.0
triggers:
  - credentials
  - password
  - connection info
  - credentials
  - secrets
required_vars: []
description: >
  Credential loading mechanism and usage conventions. No actual passwords are stored here.
  Real credentials live in config/secrets.env, which is listed in .gitignore.
---

# Credential Management Specification

## Architecture Principles

```
config/secrets.env  (actual values, never committed to Git)
        ↓ runtime injection
${VAR_NAME} in skill scripts  (placeholders, safe to commit)
        ↓ shell expansion
concrete values in actual commands
```

In any skill file (including `.md`, `.sh`, `.py`), credentials must appear only as variable references. Actual values must never be included.

---

## Credential Variable Naming Conventions

Variables are grouped by system type, following these prefix rules:

| Prefix | Scope | Example Variable Name |
|--------|-------|----------------------|
| `SSH_` | SSH login credentials | `SSH_DEFAULT_USER`, `SSH_DEFAULT_PASS` |
| `DB_` | Database credentials | `DB_<product>_USER`, `DB_<product>_PASS` |
| `CACHE_` | Cache service credentials | `CACHE_<product>_PASS` |
| `MQ_` | Message queue credentials | `MQ_<product>_USER`, `MQ_<product>_PASS` |
| `MON_` | Monitoring system credentials | `MON_<product>_USER`, `MON_<product>_PASS` |
| `WEBHOOK_` | Webhook secrets | `WEBHOOK_SECRET` |
| `STORAGE_` | Object storage credentials | `STORAGE_<product>_ACCESS_KEY` |

Specific variable names are defined by users in `config/secrets.env` based on their own tech stack, and declared in the `required_vars` field of the skills that use them.

---

## Correct Usage in Skill Scripts

```bash
# Correct: reference variables, values injected at runtime
ssh ${SSH_DEFAULT_USER}@${NODE_DB} "command"

# Wrong: hardcoded credentials (detected and blocked by scripts/verify.sh)
ssh admin@192.168.1.10 "command"
```

---

## .gitignore Must Include

```
config/secrets.env
inventory/hosts.yaml
*.env
!*.env.example
```

`scripts/install.sh` automatically ensures these entries exist during initialization.

---

## Credential Template

`config/secrets.env.example` is the template for the credentials file. It contains naming conventions and grouping notes, with all values left empty or set to placeholders.

After running `bash scripts/install.sh`, it is automatically copied to `config/secrets.env`, where users fill in actual values.

The credential template itself can be committed to Git. The actual credentials file (`secrets.env`) must never be committed.