---
name: mcp-supply-chain
title: MCP Supply Chain Controls
soul: SOUL.md
security: SECURITY.md
persona: diagnoser
version: 1.0
triggers:
  - MCP
  - model context protocol
  - tool server
  - MCP supply chain
depends_on: []
required_vars: []
description: >
  Enforces MCP allowlists, pinned versions, no ad-hoc installs, and re-review on tool description changes.
---

# MCP Supply Chain Controls

> MCP servers change the tools and descriptions an Agent sees — treat them as supply chain. Production must not “add one in the session”.

## Mandatory Policy

1. **Allowlist only:** servers listed in `security/mcp-allowlist.yaml` (from the example).
2. **Pin versions:** no `@latest` or floating tags; record `version` or `integrity` (sha256).
3. **No ad-hoc install:** `policy.allow_ad_hoc_install: false`; unlisted session `mcp add` → block.
4. **Re-describe review:** `require_redescribe_review: true`; name/description/schema changes update `last_reviewed` with owner sign-off.
5. **Credential filtering:** enable Hermes MCP credential filtering; assume env can be read after injection.

## Review Steps

1. Export enabled MCP servers and versions.
2. Diff against the allowlist; disable extras immediately.
3. Diff tool-description snapshots since last review; pending re-review blocks production use.
4. Confirm no `@latest` and no ad-hoc.
5. Emit `pass|blocked` with evidence (allowlist hash, review record).

## Output

```yaml
mcp_servers_reviewed: <n>
allowlist_hash: <hash>
ad_hoc_forbidden: true
latest_forbidden: true
redescribe_pending: []
status: pass|blocked
```
