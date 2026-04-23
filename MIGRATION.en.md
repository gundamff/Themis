# MIGRATION.md — Migration Guide

> Target audience: You have an existing Hermes Agent configuration that has been running locally for a while.
> Goal: Migrate to the Themis directory structure, introducing the Three Laws, credential externalization, and skill layering.

---

## Migration Overview


| Phase     | Content                                           | Order                          |
| --------- | ------------------------------------------------- | ------------------------------ |
| Phase 1   | Create skeleton files (SOUL/config/inventory/secrets) | Do first; foundation for all subsequent steps |
| Phase 2   | Migrate Skills                                    | Process file by file           |
| Phase 3   | Memory Cleanup                                    | Clean up old README.md last    |
| Phase 4   | Verification                                      | After everything is done       |


---

## Phase 1: Create Skeleton Files

### 1.1 Create SOUL.md

Copy from `Themis/SOUL.md` to your Hermes root directory (typically `~/.hermes/` or your Hermes project directory):

```bash
cp Themis/SOUL.md ~/.hermes/SOUL.md
```

**Verify**: Confirm it contains the Three Laws and the frontmatter has `immutable: true`:

```bash
grep -E "immutable:|First Law|Second Law|Third Law" ~/.hermes/SOUL.md && echo OK || echo FAIL
```

### 1.2 Create Credentials File

**Never commit this to Git.**

```bash
cp Themis/config/secrets.env.example ~/.hermes/config/secrets.env
# Then edit and fill in actual values
vi ~/.hermes/config/secrets.env
```

Add to `.gitignore` immediately:

```bash
echo "config/secrets.env" >> ~/.hermes/.gitignore
echo "inventory/hosts.yaml" >> ~/.hermes/.gitignore
```

**Verify**:

```bash
grep 'secrets.env' ~/.hermes/.gitignore && echo OK || echo FAIL
```

### 1.3 Create `inventory/hosts.yaml` (Your Personal Inventory)

This file holds your environment's actual IPs. It is not open-sourced and is only used locally:

```bash
mkdir -p ~/.hermes/inventory
cp Themis/inventory/hosts.example.yaml ~/.hermes/inventory/hosts.yaml
# Then edit, replacing <NODE_X_IP> with actual IPs, and add services sections as needed
vi ~/.hermes/inventory/hosts.yaml
```

### 1.4 Update config.yaml

Merge the following fields into your existing `config.yaml` (keep your original platforms configuration unchanged):

```yaml
soul: ~/.hermes/SOUL.md
inventory: ~/.hermes/inventory/hosts.yaml
secrets: ~/.hermes/config/secrets.env
memory:
  - ~/.hermes/memory/index.md
  - ~/.hermes/memory/user-profile.md
```

**Verify**:

```bash
grep -E "soul:|inventory:|secrets:" ~/.hermes/config.yaml && echo OK
```

---

## Phase 2: Migrate Skills

### File Decision Principles

For each file in your old skills, process it according to this decision tree:

1. **Contains Three Laws text** → Remove the text, replace with a `soul: SOUL.md` reference
2. **Contains hardcoded IPs** → Replace with `${NODE_XXX}` variables, defined in inventory
3. **Contains hardcoded passwords/usernames** → Replace with `${VAR_NAME}` variables, defined in secrets.env
4. **Contains business-specific table names/topics/collection names** → Add as variables in the inventory's business configuration section
5. **Contains user names/contact info** → Migrate to `memory/user-profile.md`, remove from the skill

### General Method for Variable Substitution

For each migrated SKILL.md, perform substitutions of the following types (using your own old values):

```bash
SKILL_FILE="skills/xxx/SKILL.md"

# SSH credentials (replace with your old config's actual username and password)
sed -i "s/OLD_SSH_USERNAME/\${SSH_DEFAULT_USER}/g" "$SKILL_FILE"
sed -i "s/OLD_SSH_PASSWORD/\${SSH_DEFAULT_PASS}/g" "$SKILL_FILE"

# Database passwords (replace with your old config's actual password)
sed -i "s/OLD_DB_PASSWORD/\${DB_<PRODUCT_NAME>_PASS}/g" "$SKILL_FILE"

# IP addresses (replace with your old config's actual IPs)
sed -i "s/<OLD_NODE1_IP>/\${NODE_CONTROL}/g" "$SKILL_FILE"
sed -i "s/<OLD_NODE2_IP>/\${NODE_APP}/g" "$SKILL_FILE"
# ... and so on
```

**Verify each file** (replace the placeholders below with actual values from your old config):

```bash
grep -n '<OLD_SSH_PASSWORD>\|<OLD_DB_PASSWORD>\|<OLD_IP_ADDRESS>' "$SKILL_FILE" \
  && echo "FAIL: still has hardcoded values" || echo "OK: no plaintext credentials"
```

**Post-migration full verification**:

```bash
# Search skills/ for anything that looks like a password or IP
bash scripts/verify.sh
```

### Required Frontmatter Fields After Migration

Every SKILL.md must include the following at the top:

```yaml
---
name: <unique skill identifier>
title: <human-readable name>
soul: SOUL.md           # Required
persona: <observer|diagnoser|executor>  # Required
version: 1.0
triggers:               # Required, at least 3
  - <trigger-word-1>
  - <trigger-word-2>
  - <trigger-word-3>
depends_on:             # If there are dependencies
  - infra/inventory-loader
required_vars:          # Declare variable names used
  - <VAR_NAME>
description: <one-sentence description>
---
```

---

## Phase 3: Memory Cleanup

### 3.1 Where Old README.md Sections Go


| Section Content                            | Destination                                        |
| ------------------------------------------ | -------------------------------------------------- |
| Three Laws / operations principles         | Delete (already moved to SOUL.en.md)               |
| Platform configuration notes (Open WebUI etc.) | Keep in INSTALL.md appendix                        |
| Machine inventory (IPs, server list)       | Delete (already moved to inventory/hosts.yaml)     |
| Backup plan table                          | Delete (already abstracted into skills/backup methodology) |
| Data association rules (business schema info) | Move into local inventory's business configuration section |
| Incident experience records                | May keep in local skill's "notes" section, but with business names anonymized |
| User profile (owner name, authorization scope) | Move to memory/user-profile.md                     |


### 3.2 Create memory/user-profile.md

```bash
cp Themis/memory/user-profile.example.md ~/.hermes/memory/user-profile.md
# Fill in actual owner, authorization scope, and communication preferences
vi ~/.hermes/memory/user-profile.md
```

### 3.3 Update memory/index.md

```bash
cp Themis/memory/index.md ~/.hermes/memory/index.md
# If you have local custom skills, append trigger word mappings in index.md
```

---

## Phase 4: Verification

### 4.1 Compliance Check (Recommended to Run First)

```bash
bash scripts/verify.sh
# All OK, no FAIL items
```

### 4.2 Three Laws Duplication Check

```bash
# skills/ should not contain Three Laws text (only SOUL.en.md is the authoritative source)
grep -rln "First Law\|Second Law\|Third Law" skills/
# Expected: no output
```

### 4.3 Plaintext Credentials Check

```bash
# skills/ and memory/ should not contain real passwords or real IPs
# Check using known passwords/IPs from your old config:
grep -rn '<YOUR_OLD_PASSWORD>\|<YOUR_OLD_IP>' skills/ memory/ \
  && echo "FAIL: still has plaintext credentials" || echo "OK"
```

### 4.4 Skill Frontmatter Check

```bash
for f in $(find skills/ -name "SKILL.md"); do
  grep -q "soul:" "$f" || echo "MISSING soul: $f"
  grep -q "persona:" "$f" || echo "MISSING persona: $f"
  grep -q "triggers:" "$f" || echo "MISSING triggers: $f"
done
```

---

## Post-Migration Directory Structure (Final State)

```
~/.hermes/
├── SOUL.md                          # Copied from Themis, immutable
├── config/
│   ├── config.yaml                  # Contains soul/inventory/secrets/4-persona configuration
│   └── secrets.env                  # [gitignored] Your real credentials
├── memory/
│   ├── index.md                     # Skills trigger word index
│   └── user-profile.md              # Your operator information
├── inventory/
│   └── hosts.yaml                   # [gitignored] Your machine inventory (with actual IPs)
└── skills/
    ├── safety/preflight-and-audit/  # From Themis, methodology layer
    ├── infra/inventory-loader/      # From Themis, methodology layer
    ├── infra/credentials/           # From Themis, methodology layer
    ├── observe/                     # From Themis (methodology) + local concrete implementation
    ├── diagnose/                    # From Themis (methodology) + local concrete implementation
    ├── backup/                      # From Themis (methodology) + local concrete implementation
    └── integrate/webhook-subscriptions/  # From Themis, ready to use
```

---

## Notes

1. `inventory/hosts.yaml` contains actual IPs. Do not upload to public code repositories.
2. `secrets.env` contains real credentials. Do not commit even in private repositories.
3. Hermes does not need downtime during migration. Skill file changes take effect automatically in the next session.
4. You can keep the old skills directory around. Delete it only after all migration checks pass.
5. Local concrete skills can be extended at any time without affecting the Themis framework's methodology layer.