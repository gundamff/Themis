# INSTALL.md — Installation Guide

## Prerequisites

- Hermes CLI installed (`hermes --version` returns output)
- Python 3.8+ (for audit_logger.py)
- Linux/macOS (Windows requires WSL or Git Bash to run scripts/*.sh)

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/gundamff/Themis
cd Themis
```

### Step 2: Run the Initialization Script

```bash
bash scripts/install.sh
```

The script automatically:
- Copies configuration files from `.example` templates (won't overwrite existing files)
- Checks `.gitignore` (ensures `secrets.env` and `hosts.yaml` are not committed)
- Creates the audit log directory
- Runs `verify.sh` for basic checks

### Step 3: Fill in Your Environment Information

**Credentials** (required; without them, specific skills cannot connect to remote systems):

```bash
vi config/secrets.env
# Refer to config/secrets.env.example for field descriptions, then fill in your actual credentials
```

**Host Inventory** (you must fill in your actual IPs):

```bash
vi inventory/hosts.yaml
# Replace example IPs with your actual IPs
# Alias names (NODE_CONTROL, etc.) are conventions you can adjust for your environment
# But if you change them, the variable names referenced in local skills must be updated accordingly
```

**Operator Profile** (recommended):

```bash
vi memory/user-profile.md
```

### Step 4: Write Your Concrete Skills

Themis provides a methodology framework. Concrete system skills need to be implemented by you. Create local skill files and declare `depends_on` to reference the methodology layer:

```yaml
# Example: local MongoDB backup skill
---
name: my-mongodb-backup
soul: SOUL.en.md
persona: executor
depends_on:
  - backup
  - infra/inventory-loader
  - safety/preflight-and-audit
required_vars:
  - NODE_STORAGE
  - SSH_DEFAULT_PASS
---
# Write your MongoDB backup commands here
```

### Step 5: Configure and Start Hermes

```bash
hermes gateway setup   # First-time platform configuration
hermes gateway run
```

Make sure the top of `config/config.yaml` has the following fields (add them manually if missing):

```yaml
soul: SOUL.en.md
inventory: inventory/hosts.yaml
secrets: config/secrets.env
memory:
  - memory/index.md
  - memory/user-profile.md
```

### Step 6: Verify

```bash
# Check the gateway
curl http://localhost:8642/health

# Test as observer (read-only, safest)
hermes chat --persona observer "What is the current system status?"
```

---

## Appendix A: Open WebUI Integration

Connect Hermes to Open WebUI as an OpenAI-compatible API:

```
In config/config.yaml, set platforms.api_server:
  host: "0.0.0.0"
  port: 8642
  cors_origins:
    - "<Open WebUI address>"   # e.g. http://localhost:3000

Open WebUI connection settings:
  API URL: http://<Hermes host address>:8642/v1
  (When accessing the host from a Docker container, use host.docker.internal)

Restart command:
  sudo hermes gateway restart --system
```

---

## Appendix B: Webhook Quick Configuration

Allow external alerting/CI/CD systems to automatically trigger the Agent:

```bash
# Enable the webhook platform (set in config/config.yaml):
# platforms.webhook.enabled: true
# platforms.webhook.port: 8644
# platforms.webhook.secret: "${WEBHOOK_SECRET}"

# After restarting, subscribe to an alert webhook
hermes webhook subscribe ops-alert \
  --prompt "Alert: {alert.name}\nSeverity: {alert.severity}\nDetails: {alert.message}\n\nPlease diagnose." \
  --skills "diagnose,observe" \
  --deliver <your notification channel> \
  --deliver-chat-id "<channel ID>"

# Test
hermes webhook test ops-alert --payload '{"alert":{"name":"test","severity":"high","message":"test alert"}}'
```

See `skills/integrate/webhook-subscriptions/SKILL.en.md` for details.

---

## FAQ

| Issue | Solution |
|-------|----------|
| `hermes: command not found` | Install the Hermes CLI; see the official documentation |
| `Permission denied: /var/log/hermes` | `sudo mkdir -p /var/log/hermes && sudo chmod 755 /var/log/hermes` |
| Skill not responding | Check that trigger words in `memory/index.md` match |
| Cannot connect to target server | Check IPs in `inventory/hosts.yaml` and credentials in `secrets.env` |
| verify.sh reports FAIL | Fix each item as prompted: check for plaintext passwords / SOUL integrity / frontmatter |