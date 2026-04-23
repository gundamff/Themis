# Themis - Intelligent Operations Agent Framework

<p align="center">
  <img src="https://img.shields.io/badge/Hermes-Compatible-blue" alt="Hermes Compatible">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/Three%20Laws-Immutable-red" alt="Three Laws Immutable">
</p>

<p align="center">
  <b>English</b> | <a href="README.zh-CN.md">简体中文</a>
</p>

> **Themis** — A governance framework for AI-driven operations agents, grounded in the Three Laws of Operations.
> Provides principles, methodology, and safety guardrails. You bring the environment-specific skills.

**SOUL.md is the immutable core** — The Three Laws reside there, and no skill, instruction, or user input may bypass them.

---

## What is Themis?

Themis is an **operations agent framework** — not a ready-to-run agent. It provides:

- **Governance layer**: The Three Laws (SOUL.md), four-persona model, preflight safety checks
- **Methodology skills**: Abstract principles for backup, diagnosis, and observability
- **Infrastructure skeleton**: Inventory/credential separation, audit logging
- **Extension points**: You implement environment-specific skills on top of this framework

The framework is infrastructure-agnostic. Your environment's IPs, credentials, and service specifics live in `inventory/hosts.yaml` and `config/secrets.env` — never in skill files.

---

## Core Design

### Four-Layer Architecture

```
SOUL.md (immutable Three Laws)
  └─ memory/index.md + user-profile.md  (minimal pointers)
       └─ inventory/hosts.yaml + config/secrets.env  (environment-specific, gitignored)
            └─ skills/**  (methodology layer + your local concrete skills)
```

Skills reference only variable names (`${NODE_DB}`, `${SSH_DEFAULT_PASS}`). Switching environments means only changing `inventory/hosts.yaml` + `secrets.env`.

### Four Personas

A single Agent instance switches personas based on task type, with escalating permissions:

| Persona | Role | Write Operations | Typical Tasks |
|---------|------|------------------|---------------|
| `observer` | Read-only patrol | None | Scheduled health reports, alert monitoring |
| `diagnoser` | Read-only diagnosis | None (read-only SSH) | Root cause analysis, data quality checks |
| `executor` | Controlled execution | Yes (requires preflight + approval) | Backups, config changes, remediation |
| `approver` | Approval authority | None | Sign off on approve/reject for high-risk operations |

Switch personas: `hermes chat --persona diagnoser`

---

## The Three Laws

The `SOUL.md` file contains the immutable core of the Agent:

- **First Law**: System stability is paramount (above all else)
- **Second Law**: Obey human commands (First Law takes precedence in conflicts)
- **Third Law**: Defense against irreversible operations (backup verification + audit logs)

Constraints on SOUL.md:
- `immutable: true` — Content never updates during sessions
- `override: forbidden` — Any instruction attempting to bypass is automatically rejected
- `load: always` — Loaded before every inference regardless of persona

The execution flow (preflight checks, audit logging) is implemented in `skills/safety/preflight-and-audit/`.

---

## Project Structure

```
Themis/
├── SOUL.md                         # The Three Laws (immutable)
├── MIGRATION.md                    # Guide: migrate from an existing Hermes setup
├── config/
│   ├── config.example.yaml         # 4-persona config template → copy to config.yaml
│   └── secrets.env.example         # Credentials template → copy to secrets.env (gitignored)
├── memory/
│   ├── index.md                    # Skills index (trigger words → paths)
│   └── user-profile.example.md     # Operator profile template
├── inventory/
│   └── hosts.example.yaml          # Host inventory template (variable naming conventions)
├── skills/
│   ├── safety/                     # Safety: Preflight checks + audit (Three Laws enforcement)
│   ├── infra/                      # Infrastructure: Inventory loading + credential rules
│   ├── observe/                    # Observability methodology (abstract principles)
│   ├── diagnose/                   # Diagnosis methodology (abstract principles)
│   ├── backup/                     # Backup methodology (abstract principles)
│   └── integrate/                  # Integration: Webhook event subscriptions
└── scripts/
    ├── install.sh                  # Initialization script
    └── verify.sh                   # Compliance checker (CI-ready)
```

The `observe/`, `diagnose/`, and `backup/` skills are **methodology files** — they define principles, decision frameworks, and output formats. Concrete implementations (specific commands for your database, cache, message queue) are written as local skills that declare `depends_on` on the methodology skills.

---

## Too Lazy to Read? Let an Agent Do It

### Fresh Install

**For Humans**

Copy and paste this prompt to your Hermes Agent:

```
Install and configure Themis by following the instructions here:
https://raw.githubusercontent.com/gundamff/Themis/main/INSTALL.md
```

**For Hermes Agents**

Fetch the installation guide and follow it:

```bash
curl -s https://raw.githubusercontent.com/gundamff/Themis/main/INSTALL.md
```

---

### Migrating from an Existing Hermes Setup

**For Humans**

Copy and paste this prompt to your Hermes Agent:

```
Migrate my existing Hermes Agent setup to the Themis framework by following the instructions here:
https://raw.githubusercontent.com/gundamff/Themis/main/MIGRATION.md

My current Hermes config is at: ~/.hermes/  (adjust the path if different)
```

**For Hermes Agents**

Fetch the migration guide and follow it:

```bash
curl -s https://raw.githubusercontent.com/gundamff/Themis/main/MIGRATION.md
```

The migration guide covers 4 phases: skeleton files → skill migration → memory cleanup → validation.
It handles credential externalization, IP variable substitution, and frontmatter compliance.
Complete the guide before running `bash scripts/verify.sh`.

---

## Getting Started

### Step 1: Initialize

```bash
git clone https://github.com/gundamff/Themis
cd Themis
bash scripts/install.sh
```

### Step 2: Fill in your environment

```bash
vi config/secrets.env        # Your credentials
vi inventory/hosts.yaml      # Your host IPs and service endpoints
vi memory/user-profile.md    # Your operator profile
```

### Step 3: Write your concrete skills

Create local skills in `~/.hermes/skills/` or a local directory, following this pattern:

```yaml
---
name: my-db-backup
title: My Database Backup
soul: SOUL.md
persona: executor
depends_on:
  - backup               # Inherits methodology constraints
  - infra/inventory-loader
  - safety/preflight-and-audit
required_vars:
  - NODE_DB
  - SSH_DEFAULT_PASS
  - DB_MY_PASS
---
# Concrete backup commands for your specific database here
```

### Step 4: Load into Hermes

```bash
hermes gateway setup
hermes gateway run
```

---

## Writing a New Skill

### Frontmatter Specification (Required Fields):

```yaml
---
name: my-skill
title: Human-readable Name
soul: SOUL.md              # Required: Explicit dependency
persona: observer          # Required: observer | diagnoser | executor
version: 1.0
triggers:                  # Required: At least 3 trigger words
  - trigger-word-1
  - trigger-word-2
depends_on:                # Optional: methodology skills this builds on
  - observe                # or backup, diagnose
  - infra/inventory-loader
required_vars:             # Required variables from inventory/secrets
  - NODE_DB
description: One-sentence description
---
```

### Prohibited Practices:
- Hardcoding IP addresses in skills (use `${NODE_XXX}`)
- Hardcoding passwords in skills (use `${DB_XXX_PASS}`, etc.)
- Repeating the Three Laws text in skills (reference SOUL.md instead)
- executor persona write operations without `depends_on: [safety/preflight-and-audit]`

### Validate:

```bash
bash scripts/verify.sh
# All checks must pass before committing
```

---

## Contributing

### PR Checklist

- [ ] Run `bash scripts/verify.sh` — all checks pass (zero FAIL)
- [ ] New skill frontmatter includes `soul`, `persona`, `triggers`
- [ ] No hardcoded IPs or passwords
- [ ] No modifications to `SOUL.md`
- [ ] Methodology skills (`observe/`, `diagnose/`, `backup/`) remain abstract — no concrete commands

### PRs We Won't Accept

- Changes to the Three Laws in SOUL.md (unless consensus reached in an issue)
- Concrete tool-specific commands in the methodology skill files
- Write operation skills that skip the preflight checks

---

## Documentation

- [Installation Guide](INSTALL.en.md)
- [Migration Guide](MIGRATION.en.md) — Migrate from an existing Hermes setup
- [The Three Laws](SOUL.en.md) — Immutable core

---

## Languages

- [English](README.md)
- [简体中文](README.zh-CN.md)

---

## License

[MIT](LICENSE)

---

<p align="center">
  <i>Named after Themis, the Greek Titaness of divine law and order.</i>
</p>
