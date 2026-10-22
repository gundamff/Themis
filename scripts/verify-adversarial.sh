#!/usr/bin/env bash
# scripts/verify-adversarial.sh — 静态/规程对抗检查（非 live LLM 红队）
# 由 scripts/verify.sh 的 SEC-ADV 调用；也可单独运行。
set -uo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE"

FAIL=0
red() { echo -e "\033[31m[ADV-FAIL]\033[0m $1"; FAIL=$((FAIL+1)); }
ok()  { echo -e "\033[32m[ADV-OK ]\033[0m $1"; }

echo "=== Themis 对抗静态检查 ==="

# ADV-01: approvals.mode 不得为 off
if grep -A5 -E '^approvals:' config/config.example.yaml 2>/dev/null | grep -qE 'mode:\s*off'; then
  red "ADV-01: config.example approvals.mode=off"
else
  ok "ADV-01: approvals 未设 off"
fi
if grep -qF "approvals.mode" skills/safety/preflight-and-audit/SKILL.md && \
   grep -qE '设为 `off`|mode.*off' skills/safety/preflight-and-audit/SKILL.md; then
  ok "ADV-01: preflight 阻断关审批"
else
  red "ADV-01: preflight 缺少关审批阻断"
fi

# ADV-02: YOLO
if grep -qE 'HERMES_YOLO_MODE' SECURITY.md SOUL.md config/config.example.yaml 2>/dev/null; then
  ok "ADV-02: 禁 YOLO 条文存在"
else
  red "ADV-02: 缺少 YOLO 禁令"
fi

# ADV-03: observe toolsets
OBS=templates/profiles/themis-observe/config.snippet.yaml
for ts in browser web code_execution; do
  if grep -qE "^\s*-\s*${ts}\s*$" "$OBS" 2>/dev/null; then
    ok "ADV-03: observe 禁用 $ts"
  else
    red "ADV-03: observe 未禁用 $ts"
  fi
done

# ADV-04: argv_digest ticket
if grep -qF "argv_digest" skills/safety/preflight-and-audit/SKILL.md && \
   [ -f security/schemas/approval-ticket.example.yaml ] && \
   grep -qF "argv_digest" security/schemas/approval-ticket.example.yaml; then
  ok "ADV-04: 审批票据 argv_digest 证据齐全"
else
  red "ADV-04: 缺少 argv_digest 票据证据"
fi

# ADV-05: MCP
AL=security/mcp-allowlist.example.yaml
if [ -f "$AL" ] && grep -qE 'allow_ad_hoc_install:\s*false' "$AL" && \
   grep -qE 'allow_latest_tag:\s*false' "$AL"; then
  ok "ADV-05: MCP 禁 ad-hoc/@latest"
else
  red "ADV-05: MCP allowlist 策略不足"
fi

# ADV-06: sandbox
if grep -qiE 'docker\.sock' skills/security/privileged-plane/SKILL.md && \
   [ -f security/attestations/sandbox-not-privileged.example.md ]; then
  ok "ADV-06: 沙箱非 privileged 证据齐全"
else
  red "ADV-06: 缺少沙箱逃逸控制证据"
fi

# ADV-07: output guards
if [ -f skills/security/output-and-audit-guards/SKILL.md ] && \
   grep -qF "tool_name" security/schemas/audit-tool-event.example.json 2>/dev/null; then
  ok "ADV-07: 输出/审计护栏证据齐全"
else
  red "ADV-07: 缺少输出脱敏或 tool 审计 schema"
fi

# ADV-08: egress
if grep -qF "外联受控" SECURITY.md && \
   [ -f security/attestations/egress-allowlist.example.md ]; then
  ok "ADV-08: egress 控制证据齐全"
else
  red "ADV-08: 缺少 egress 控制证据"
fi

if [ ! -f tests/adversarial/cases.md ]; then
  red "cases.md 缺失"
else
  ok "cases.md 存在"
fi

echo ""
echo "ADV FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
