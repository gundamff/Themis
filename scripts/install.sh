#!/usr/bin/env bash
# scripts/install.sh — Hermes Ops Agent 初始化安装脚本
# 用法: bash scripts/install.sh
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE"

echo "=== Hermes Ops Agent 初始化 ==="

# Step 1: 检查 Hermes CLI
if ! command -v hermes &>/dev/null; then
  echo "[ERROR] hermes 未找到。请先安装 Hermes:"
  echo "  pip install hermes-ai  # 或按官方文档安装"
  exit 1
fi
echo "[OK] hermes $(hermes --version 2>/dev/null || echo '版本未知')"

# Step 2: 复制配置文件模板（不覆盖已有文件）
copy_if_missing() {
  local src="$1" dst="$2"
  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"
    echo "[INIT] 已创建 $dst（请编辑填写实际值）"
  else
    echo "[SKIP] $dst 已存在，跳过"
  fi
}

copy_if_missing "config/config.example.yaml"    "config/config.yaml"
copy_if_missing "config/secrets.env.example"    "config/secrets.env"
copy_if_missing "inventory/hosts.example.yaml"  "inventory/hosts.yaml"
copy_if_missing "memory/user-profile.example.md" "memory/user-profile.md"

# Step 3: 检查 .gitignore
GITIGNORE="$BASE/.gitignore"
if [ ! -f "$GITIGNORE" ]; then
  cat > "$GITIGNORE" << 'EOF'
config/secrets.env
inventory/hosts.yaml
*.env
!*.env.example
__pycache__/
*.pyc
EOF
  echo "[INIT] 已创建 .gitignore"
else
  # 确保关键条目存在
  for entry in "config/secrets.env" "inventory/hosts.yaml"; do
    if ! grep -qF "$entry" "$GITIGNORE"; then
      echo "$entry" >> "$GITIGNORE"
      echo "[ADD] .gitignore 新增: $entry"
    fi
  done
  echo "[OK] .gitignore 已存在"
fi

# Step 4: 创建审计日志目录
AUDIT_DIR="/var/log/hermes"
if [ ! -d "$AUDIT_DIR" ]; then
  if sudo mkdir -p "$AUDIT_DIR" && sudo chmod 755 "$AUDIT_DIR"; then
    echo "[INIT] 已创建审计目录 $AUDIT_DIR"
  else
    echo "[WARN] 无法创建 $AUDIT_DIR，可在 config.yaml 中修改 audit.sink 路径"
  fi
else
  echo "[OK] 审计目录 $AUDIT_DIR 已存在"
fi

# Step 5: 运行 verify.sh
echo ""
echo "=== 运行合规检查 ==="
bash "$BASE/scripts/verify.sh"

echo ""
echo "=== 初始化完成 ==="
echo ""
echo "下一步："
echo "  1. 编辑 config/secrets.env        — 填写你的实际凭据"
echo "  2. 编辑 inventory/hosts.yaml      — 填写你的实际 IP 和服务端点"
echo "  3. 编辑 memory/user-profile.md    — 填写操作员信息"
echo ""
echo "注意：Themis 是原则与方法论框架，不是开箱即用的 Agent。"
echo "你需要在本地编写针对自身系统的具体 skill，声明 depends_on 引用方法论层。"
echo ""
echo "  4. 在本地创建具体 skill（参见 INSTALL.md Step 4）"
echo "  5. hermes gateway setup   # 配置平台"
echo "  6. hermes gateway run     # 启动服务"
echo ""
echo "参考文档：INSTALL.md（详细步骤）| MIGRATION.md（从已有配置迁移）"