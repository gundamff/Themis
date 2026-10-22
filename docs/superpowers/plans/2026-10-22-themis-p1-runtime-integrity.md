# Themis P1 Runtime Integrity Implementation Plan

> **For agentic workers:** Implement task-by-task. Prefer TDD via `scripts/verify.sh` SEC-* gates.

**Goal:** Land crosswalk P1 items 5–9 as procedures + templates + verify gates (no approval microservice).

**Architecture:** Extend privileged-plane and preflight; add MCP/output skills, schemas, attestations; add static adversarial verifier invoked from `verify.sh`.

**Tech Stack:** Markdown skills, YAML/JSON examples, bash verify scripts.

**Global Constraints:** No real secrets/IPs; bilingual SKILL.md + SKILL.en.md; Hermes-native keys only; adversarial = static/procedural not live LLM.

---

### Task 1: SEC gates (fail first)

**Files:** Modify `scripts/verify.sh`

- [ ] Add `SEC-SANDBOX`, `SEC-TICKET`, `SEC-MCP`, `SEC-OUTPUT`, `SEC-ADV` stubs that FAIL when artifacts missing
- [ ] Run `bash scripts/verify.sh` → expect FAIL > 0
- [ ] Commit optional (or batch at end)

### Task 2: Item 9 sandbox / privileged

**Files:** privileged-plane SKILL(+en); `security/attestations/sandbox-not-privileged.example.md`

- [ ] Add Agent/sandbox section (no privileged, no docker.sock, etc.)
- [ ] Add attestation template
- [ ] SEC-SANDBOX passes

### Task 3: Item 5 approval ticket

**Files:** `security/schemas/approval-ticket.example.yaml`; preflight SKILL(+en); AGENTS.md; SECURITY.md one-liner optional

- [ ] Schema + preflight argv_digest/expires/nonce/consume checks
- [ ] SEC-TICKET passes

### Task 4: Item 6 MCP

**Files:** mcp-allowlist.example.yaml; mcp-supply-chain skill(+en); mcp attestation; config comment

- [ ] SEC-MCP passes

### Task 5: Item 8 output/audit

**Files:** output-and-audit-guards skill(+en); audit-tool-event.example.json

- [ ] SEC-OUTPUT passes

### Task 6: Item 7 adversarial

**Files:** `tests/adversarial/cases.md`; `scripts/verify-adversarial.sh`; wire into verify.sh

- [ ] SEC-ADV passes; full verify FAIL:0

### Task 7: Docs + finish

- [ ] Update design status + crosswalk P1 done
- [ ] Commit on `feat/hermes-security-hardening`
