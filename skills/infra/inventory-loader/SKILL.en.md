---
name: inventory-loader
title: Infrastructure Inventory Loader
soul: SOUL.md
persona: observer, diagnoser, executor
version: 1.0
triggers:
  - machine inventory
  - server list
  - host info
  - view nodes
  - inventory
  - hosts
required_vars: []
description: >
  Reads the infrastructure inventory from inventory/hosts.yaml, providing host aliases
  and service endpoints for other skills to reference. Contains no credentials;
  credentials are injected at runtime from config/secrets.env.
---

# Infrastructure Inventory Loader

## Purpose

This skill is a prerequisite dependency for any skill that needs to access hosts.
The `${NODE_XXX}` variables in skill scripts are resolved here to their actual values defined in the inventory.

In skills that need host information, declare at the top:

```yaml
depends_on:
  - infra/inventory-loader
```

The Agent will automatically load `inventory/hosts.yaml` before executing that skill, making the variables available.

---

## Responsibilities of the Inventory

`inventory/hosts.yaml` is the sole isolation layer between the environment and skills:

- Stores mappings of host aliases to actual IPs
- Stores environment-specific configuration such as service endpoints, ports, and paths
- **Never stores credentials** (credentials live in `config/secrets.env`)
- **Never stores business logic** (business logic lives in skills)

When switching to a new environment, you only need to modify `inventory/hosts.yaml`. Skill code stays unchanged.

---

## Variable Naming Conventions

Host aliases use the `NODE_` prefix. Service endpoints use semantic prefixes:

```
NODE_<ROLE>       — Host node IP, e.g. NODE_CONTROL, NODE_DB, NODE_APP
<SERVICE>_HOST    — Service host, e.g. KAFKA_HOST, MONGO_HOST
<SERVICE>_PORT    — Service port, e.g. REDIS_PORT, OB_PORT
<SERVICE>_<USAGE> — Other service-related paths, e.g. KAFKA_DATA_DIR
```

Specific variable names are defined by users in `inventory/hosts.yaml` based on their own environment.
All skill scripts reference only variable names (e.g. `${NODE_DB}`), never hardcoding actual IPs or paths.

---

## Loading Timing

- In each session, the Agent automatically loads before executing any operation that depends on this skill
- After modifying `hosts.yaml`, no Agent restart is needed; it reloads automatically on the next invocation
- If `hosts.yaml` does not exist, the Agent will prompt the user to initialize from the `hosts.example.yaml` template

---

## Quick View of Current Inventory

```bash
cat inventory/hosts.yaml
```

---

## Notes

- This skill never exposes passwords. Credential variables (e.g. `${SSH_DEFAULT_PASS}`) are provided by `config/secrets.env`
- If a skill requires a variable that is not defined in the inventory, a `required_vars` missing error will be raised before execution
- See `inventory/hosts.example.yaml` for an inventory template, including node structure and variable naming conventions