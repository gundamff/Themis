#!/usr/bin/env bash
# scripts/verify.sh — 合规检查脚本
# 五组检查 [1/5]…[5/5]：skills 密码 / SOUL / 方法论 / frontmatter / SEC 安全门禁
# 用法: bash scripts/verify.sh
# CI 集成: 返回非 0 表示检查失败，阻止 PR 合并

set -uo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE"

FAIL=0
WARN=0

red()   { echo -e "\033[31m[FAIL]\033[0m $1"; FAIL=$((FAIL+1)); }
warn()  { echo -e "\033[33m[WARN]\033[0m $1"; WARN=$((WARN+1)); }
ok()    { echo -e "\033[32m[ OK ]\033[0m $1"; }

echo "=== Themis 合规检查 ==="
echo ""

# ── CHECK 1: skills/ 不含明文密码特征 ──────────────────────────────
echo "--- [1/5] 检查 skills/ 中是否存在明文密码特征"

# 检测看起来像密码的模式（含特殊字符的短字符串，排除注释行和变量引用）
BAD_PATTERNS=(
  "sshpass -p '[^$][^']"          # sshpass -p 'xxx'（非变量值）
  '-p"[^$][^"]'                   # -p"xxx"（非变量值）
  "password.*=.*['\"][^$\\\${][^'\"]{4,}['\"]"
)

FOUND_SECRETS=0
for pattern in "${BAD_PATTERNS[@]}"; do
  matches=$(grep -rn --include="*.md" --include="*.sh" --include="*.py" \
    -E "$pattern" skills/ 2>/dev/null | grep -v '^\s*#' | grep -v '${' || true)
  if [ -n "$matches" ]; then
    red "疑似明文密码（pattern: $pattern）:"
    echo "$matches" | head -5
    FOUND_SECRETS=$((FOUND_SECRETS+1))
  fi
done

if [ "$FOUND_SECRETS" -eq 0 ]; then
  ok "skills/ 中未发现明文密码"
fi

# ── CHECK 2: SOUL.md 完整性 ────────────────────────────────────────
echo ""
echo "--- [2/5] 检查 SOUL.md 完整性"

SOUL="SOUL.md"
if [ ! -f "$SOUL" ]; then
  red "SOUL.md 不存在！"
else
  # 必须包含的关键字段
  for required in "immutable: true" "override: forbidden" "load: always" \
                  "第一定律" "第二定律" "第三定律"; do
    if grep -qF "$required" "$SOUL"; then
      ok "SOUL.md 包含: $required"
    else
      red "SOUL.md 缺少必要内容: $required"
    fi
  done
fi

# ── CHECK 3: 三个方法论 SKILL.md 存在 ─────────────────────────────
echo ""
echo "--- [3/5] 检查方法论 SKILL.md 是否存在"

for methodology in "skills/observe/SKILL.md" "skills/diagnose/SKILL.md" "skills/backup/SKILL.md"; do
  if [ -f "$methodology" ]; then
    ok "$methodology 存在"
  else
    red "$methodology 不存在（方法论层缺失）"
  fi
done

# ── CHECK 4: 每个 SKILL.md 声明了 persona 和 triggers ─────────────
echo ""
echo "--- [4/5] 检查每个 SKILL.md 的 frontmatter 完整性"

while IFS= read -r -d '' skill_file; do
  skill_name=$(dirname "$skill_file" | xargs basename)
  
  # 跳过非 skills/ 目录下的 md 文件
  if [[ "$skill_file" != skills/* ]]; then
    continue
  fi

  has_persona=$(grep -cE "^persona:" "$skill_file" 2>/dev/null || echo 0)
  has_triggers=$(grep -cE "^triggers:" "$skill_file" 2>/dev/null || echo 0)
  has_soul=$(grep -cE "^soul:" "$skill_file" 2>/dev/null || echo 0)

  if [ "$has_persona" -eq 0 ]; then
    warn "$skill_file 缺少 persona 声明"
  fi
  if [ "$has_triggers" -eq 0 ]; then
    warn "$skill_file 缺少 triggers 声明"
  fi
  if [ "$has_soul" -eq 0 ]; then
    warn "$skill_file 缺少 soul: SOUL.md 声明"
  fi

  if [ "$has_persona" -gt 0 ] && [ "$has_triggers" -gt 0 ] && [ "$has_soul" -gt 0 ]; then
    ok "$skill_file frontmatter 完整"
  fi
done < <(find skills/ -name "SKILL.md" -print0 2>/dev/null)

# ── CHECK 5: SEC 安全门禁 ─────────────────────────────────────────
check_sec_soul() {
  # --- SEC-SOUL ---
  if [ ! -f "SECURITY.md" ]; then
    red "SEC-SOUL: SECURITY.md 不存在"
  else
    for required in "immutable: true" "override: forbidden" "load: always" \
      "身份最小权限" "密钥不落明文" "禁止空认证" "管理面零公网" "读写隔离" \
      "不可静默关闭防护" "外联受控" "HERMES_YOLO_MODE"; do
      if grep -qF "$required" "SECURITY.md"; then
        ok "SEC-SOUL: 含 $required"
      else
        red "SEC-SOUL: 缺少 $required"
      fi
    done
  fi
  # 方案 C：SOUL 须含运行时安全短铁律
  if [ -f "SOUL.md" ]; then
    if grep -qF "安全铁律（运行时摘要" "SOUL.md" && grep -qF "外联受控" "SOUL.md"; then
      ok "SEC-SOUL: SOUL.md 含运行时安全摘要（方案 C）"
    else
      red "SEC-SOUL: SOUL.md 缺少运行时安全摘要或外联受控"
    fi
  fi
}

check_sec_bind() {
  # --- SEC-BIND ---
  if [ -f "config/config.example.yaml" ]; then
    UNMARKED_BIND=$(grep -nE 'host:\s*"?0\.0\.0\.0"?' config/config.example.yaml \
      | grep -vE '#.*(EXCEPTION|例外)' || true)
    if [ -n "$UNMARKED_BIND" ]; then
      red "SEC-BIND: config.example 默认暴露 0.0.0.0（须改为 127.0.0.1 或标注例外）"
    else
      ok "SEC-BIND: 无未标注的 0.0.0.0 绑定"
    fi
  fi
}

check_sec_approvals() {
  # --- SEC-APPROVALS ---
  if [ -f "config/config.example.yaml" ]; then
    if grep -qE 'approvals:[[:space:]]*$|approvals:' config/config.example.yaml; then
      if grep -A5 -E '^approvals:' config/config.example.yaml | grep -qE 'mode:\s*off'; then
        red "SEC-APPROVALS: 生产模板不得 approvals.mode: off"
      else
        ok "SEC-APPROVALS: approvals 未设为 off"
      fi
    else
      red "SEC-APPROVALS: config.example 缺少 approvals 配置块"
    fi
  fi
}

check_sec_profile() {
  # --- SEC-PROFILE ---
  for d in templates/profiles/themis-observe templates/profiles/themis-execute; do
    if [ -d "$d" ]; then ok "SEC-PROFILE: $d 存在"; else red "SEC-PROFILE: 缺少 $d"; fi
  done
}

check_sec_observe() {
  # --- SEC-OBSERVE: 只读落到 Hermes 原生键 ---
  local obs="templates/profiles/themis-observe/config.snippet.yaml"
  if [ ! -f "$obs" ]; then
    red "SEC-OBSERVE: 缺少 $obs"
    return
  fi
  if ! grep -qE 'disabled_toolsets:' "$obs"; then
    red "SEC-OBSERVE: 缺少 agent.disabled_toolsets"
  else
    for ts in browser web code_execution; do
      if grep -qE "^\s*-\s*${ts}\s*$" "$obs"; then
        ok "SEC-OBSERVE: disabled $ts"
      else
        red "SEC-OBSERVE: 未禁用 toolset $ts"
      fi
    done
  fi
  if grep -qE 'approvals:' "$obs" && grep -A30 -E '^approvals:' "$obs" | grep -qE 'deny:'; then
    ok "SEC-OBSERVE: 含 approvals.deny"
  else
    red "SEC-OBSERVE: 缺少 approvals.deny"
  fi
  if grep -qE 'backend:\s*docker' "$obs"; then
    ok "SEC-OBSERVE: terminal.backend docker"
  else
    red "SEC-OBSERVE: 未默认 docker 后端"
  fi
}

check_sec_deny() {
  # --- SEC-DENY: 全局模板须有 approvals.deny ---
  if [ -f "config/config.example.yaml" ]; then
    if grep -A40 -E '^approvals:' config/config.example.yaml | grep -qE 'deny:'; then
      ok "SEC-DENY: config.example 含 approvals.deny"
    else
      red "SEC-DENY: config.example 缺少 approvals.deny"
    fi
  fi
}

check_sec_docker() {
  # --- SEC-DOCKER: 生产模板默认容器 ---
  if [ -f "config/config.example.yaml" ]; then
    if grep -A10 -E '^terminal:' config/config.example.yaml | grep -qE 'backend:\s*docker'; then
      ok "SEC-DOCKER: config.example terminal.backend=docker"
    else
      red "SEC-DOCKER: config.example 未默认 docker"
    fi
  fi
}

check_sec_yolo() {
  # --- SEC-YOLO ---
  if [ -f "security/attestations/no-yolo-production.example.md" ]; then
    ok "SEC-YOLO: no-yolo attestation 模板存在"
  else
    red "SEC-YOLO: 缺少 security/attestations/no-yolo-production.example.md"
  fi
  if grep -qE 'HERMES_YOLO_MODE' config/config.example.yaml config/secrets.env.example 2>/dev/null; then
    ok "SEC-YOLO: 配置模板提及禁 YOLO"
  else
    red "SEC-YOLO: 配置模板未提及 HERMES_YOLO_MODE"
  fi
}

check_sec_egress() {
  # --- SEC-EGRESS ---
  if [ -f "security/attestations/egress-allowlist.example.md" ]; then
    ok "SEC-EGRESS: egress-allowlist attestation 模板存在"
  else
    red "SEC-EGRESS: 缺少 security/attestations/egress-allowlist.example.md"
  fi
  if grep -qiE 'egress' config/config.example.yaml AGENTS.md SECURITY.md 2>/dev/null; then
    ok "SEC-EGRESS: 文档/配置提及 egress"
  else
    red "SEC-EGRESS: 未在文档或配置中提及 egress"
  fi
}

check_sec_authz() {
  local skill="skills/security/authz-baseline/SKILL.md"
  if [ -f "$skill" ]; then ok "SEC-SKILL: $skill"; else red "SEC-SKILL: 缺少 $skill"; fi
}

check_sec_privplane() {
  local skill="skills/security/privileged-plane/SKILL.md"
  if [ -f "$skill" ]; then ok "SEC-SKILL: $skill"; else red "SEC-SKILL: 缺少 $skill"; fi
}

check_sec_skills() {
  # --- SEC-AUTHZ / SEC-PRIVPLANE / 其余 security skills ---
  for skill in \
    skills/security/threat-model/SKILL.md \
    skills/security/credentials-hygiene/SKILL.md \
    skills/security/exposure-control/SKILL.md \
    skills/security/incident-response/SKILL.md
  do
    if [ -f "$skill" ]; then ok "SEC-SKILL: $skill"; else red "SEC-SKILL: 缺少 $skill"; fi
  done
  check_sec_authz
  check_sec_privplane
}

check_sec_default() {
  # --- SEC-DEFAULT: 禁止示例中的典型默认口令字面量 ---
  DEFAULT_HITS=$(grep -rnE --include='*.md' --include='*.yaml' --include='*.yml' --include='*.env*' \
    -E 'apollo/admin|password:\s*admin\b|password:\s*public\b|NACOS_AUTH_TOKEN|admin/public' \
    config/ inventory/ templates/ skills/security/ 2>/dev/null | grep -v '禁止\|示例错误\|BAD EXAMPLE\|# BAD' || true)
  if [ -n "$DEFAULT_HITS" ]; then
    red "SEC-DEFAULT: 发现疑似默认口令字面量"
    echo "$DEFAULT_HITS" | head -20
  else
    ok "SEC-DEFAULT: 未发现默认口令字面量"
  fi
}

check_sec_secrets() {
  # --- SEC-SECRETS: attestation 模板存在 ---
  if [ -f "security/attestations/secrets-provider.example.md" ]; then
    ok "SEC-SECRETS: secrets-provider attestation 模板存在"
  else
    red "SEC-SECRETS: 缺少 security/attestations/secrets-provider.example.md"
  fi
}

echo ""
echo "--- [5/5] SEC 安全门禁"
check_sec_soul
check_sec_bind
check_sec_approvals
check_sec_deny
check_sec_docker
check_sec_profile
check_sec_observe
check_sec_yolo
check_sec_egress
check_sec_skills
check_sec_default
check_sec_secrets

# ── 结果汇总 ──────────────────────────────────────────────────────
echo ""
echo "=== 检查结果 ==="
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo -e "\033[31m检查未通过，请修复上述 FAIL 项后重新提交。\033[0m"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo ""
  echo -e "\033[33m检查通过（有警告），建议修复 WARN 项。\033[0m"
  exit 0
else
  echo ""
  echo -e "\033[32m全部检查通过。\033[0m"
  exit 0
fi