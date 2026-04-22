#!/usr/bin/env bash
# scripts/verify.sh — 合规检查脚本
# 检查三项规则：1) skills 不含明文密码  2) SOUL.md 完整性  3) 新 skill 声明了 persona/triggers
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
echo "--- [1/4] 检查 skills/ 中是否存在明文密码特征"

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
echo "--- [2/4] 检查 SOUL.md 完整性"

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
echo "--- [3/4] 检查方法论 SKILL.md 是否存在"

for methodology in "skills/observe/SKILL.md" "skills/diagnose/SKILL.md" "skills/backup/SKILL.md"; do
  if [ -f "$methodology" ]; then
    ok "$methodology 存在"
  else
    red "$methodology 不存在（方法论层缺失）"
  fi
done

# ── CHECK 4: 每个 SKILL.md 声明了 persona 和 triggers ─────────────
echo ""
echo "--- [4/4] 检查每个 SKILL.md 的 frontmatter 完整性"

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