---
name: backup
title: Backup Methodology
soul: SOUL.md
persona: executor
version: 1.0
triggers:
  - backup
  - data backup
  - backup strategy
  - backup verification
  - backup recovery
depends_on:
  - infra/inventory-loader
  - infra/credentials
  - safety/preflight-and-audit
required_vars: []
description: >
  Principles, strategy selection framework, and recoverability verification
  standards for data backup. Contains no specific tool commands — concrete
  implementations are written by users in local skills based on their own
  tech stack.
---

# Backup Methodology

> This skill is the principles and process layer. Specific backup commands
> (mysqldump, mongodump, redis BGSAVE, etc.) are implemented by users in
> their own inventory and local skills, not defined here.

---

## Core Principle: 3-2-1-1-0

Any production data backup scheme must satisfy the following conditions to be considered a "valid backup":

- **3** — Keep at least 3 copies of data (original data + 2 backups)
- **2** — Store backups on at least 2 different media (disk, object storage, tape…)
- **1** — Store at least 1 backup offsite (different datacenter / availability zone / cloud region)
- **1** — Keep at least 1 backup offline or immutable (ransomware protection)
- **0** — Zero errors in recovery testing: every backup must pass periodic recovery verification; unverified backups are considered nonexistent

Any scheme that does not satisfy 3-2-1-1-0 is not considered to have a "valid backup" before executing high-risk operations, and preflight will block the operation.

---

## Strategy Selection Framework

### Choose backup type based on data change frequency

| Data Characteristic | Recommended Strategy | Rationale |
|---------------------|---------------------|-----------|
| Frequent writes (hourly/minute-level) | Full + Incremental/WAL | Pure full backup is too costly |
| Moderate writes (daily batch) | Daily full backup | Simple, reliable, fastest recovery |
| Infrequent writes (config, parameters) | Change-triggered + weekly full | On-demand is sufficient |
| Read-only (archived data) | One-time full + immutable storage | No rotation needed |

### Choose backup frequency based on RTO/RPO requirements

- **RPO** (how much data loss is tolerable) → determines backup interval
- **RTO** (how quickly recovery must complete) → determines storage location and format

RTO < 1 hour: backups must be stored locally or near-line, with a pre-tested recovery process
RPO < 1 hour: incremental backups or streaming replication are required; daily full backups alone are insufficient

---

## Recoverability Verification Standards

A backup file existing ≠ it can be restored. The following verification steps are all mandatory:

### Verification Level 1: File Integrity (automatic, after every backup)

- Verify file size is non-zero
- Verify MD5/SHA256 digest matches the digest generated at backup time
- For compressed files, verify the archive can be fully decompressed (`gzip -t` or equivalent)

### Verification Level 2: Logical Integrity (at least weekly)

- Restore the backup file to an isolated test environment
- Run data integrity checks (row counts, key tables exist, indexes are usable)
- Record recovery time and compare against RTO

### Verification Level 3: Full Drill (quarterly)

- Simulate a real failure scenario and fully restore the entire service from backup
- Verify the application layer can connect and operate normally
- Record results and archive them as preflight `backup_verified` proof

---

## Retention and Rotation Policy

| Backup Type | Minimum Retention | Rotation Rule |
|-------------|-------------------|---------------|
| Daily full | 7 days | Auto-delete backups older than 7 days |
| Weekly full | 4 weeks | Keep the last 4 weekend backups |
| Monthly snapshot | 12 months | Keep the last 12 month-end backups |
| Pre-high-risk-operation backup | Permanent (or until next similar operation is verified successful) | No auto-rotation |

Offsite backup retention must not be shorter than local backup retention.

---

## Coupling with Preflight

Before executing any high-risk operation involving data changes, the preflight skill checks `backup_verified`:

1. The agent asks the user to confirm that the target data has a verified backup within the last 24 hours
2. The user (or automated process) provides the timestamp and storage location of the most recent backup
3. Preflight records `backup_verified = true`; only then may the operation proceed

**This step cannot be skipped.** Even if an operation appears "low-risk," any time it involves data writes or deletes, preflight must complete.

---

## Alert and Notification Principles

- Backup not completed within the expected window → immediate alert; block operations that depend on that backup
- Backup file checksum failure → immediate alert; mark the backup as invalid and trigger a re-backup
- N consecutive backup failures → escalate alert; require human intervention (N is user-defined based on RTO)
- Storage space below threshold → early warning; don't wait until the disk is full to discover the problem

---

## User Notes

This framework does not provide any concrete backup scripts. Users need to:

1. Write concrete backup skills locally based on their own database/cache/message queue tech stack
2. Enter backup storage paths, target nodes, and other parameters into `inventory/hosts.yaml`
3. Enter authentication credentials into `config/secrets.env`
4. Declare `depends_on: [backup]` in local skills to ensure methodology constraints take effect

See `skills/infra/inventory-loader` for how to declare variables, and `skills/infra/credentials` for credential standards.