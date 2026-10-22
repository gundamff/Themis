# INSTALL.md — 安装指南

## 前置条件

- Hermes CLI 已安装（`hermes --version` 有输出）
- Python 3.8+（用于 audit_logger.py）
- Linux/macOS（Windows 需要 WSL 或 Git Bash 执行 scripts/*.sh）

## 安装步骤

### Step 1：克隆仓库

```bash
git clone https://github.com/gundamff/Themis
cd Themis
```

### Step 2：运行初始化脚本

```bash
bash scripts/install.sh
```

脚本自动完成：
- 从 `.example` 模板复制配置文件（不覆盖已有文件）
- 检查 `.gitignore`（确保 `secrets.env` 和 `hosts.yaml` 不提交）
- 创建审计日志目录
- 运行 `verify.sh` 基本检查

### Step 3：填写环境信息

**凭据**（必须填写，否则具体 skill 无法连接远程系统）：

```bash
vi config/secrets.env
# 参考 config/secrets.env.example 的字段说明，填写你的实际凭据
```

**主机清单**（必须填写你的实际 IP）：

```bash
vi inventory/hosts.yaml
# 将示例 IP 替换为实际 IP
# alias 名称（NODE_CONTROL 等）是约定，可根据你的环境调整
# 但改后本地 skill 中引用的变量名也要对应改
```

**操作员信息**（推荐填写）：

```bash
vi memory/user-profile.md
```

### Step 4：编写你的具体 skill

Themis 提供方法论框架，具体的系统 skill 需要你自己实现。在本地创建 skill 文件，声明 `depends_on` 引用方法论层：

```yaml
# 示例：本地 MongoDB 备份 skill
---
name: my-mongodb-backup
soul: SOUL.md
persona: executor
depends_on:
  - backup
  - infra/inventory-loader
  - safety/preflight-and-audit
required_vars:
  - NODE_STORAGE
  - SSH_DEFAULT_PASS
---
# 在此处编写你的 MongoDB 备份命令
```

### Step 5：配置并启动 Hermes

```bash
hermes gateway setup   # 首次配置平台
hermes gateway run
```

确认 `config/config.yaml` 顶部有以下字段（如无则手动添加）：

```yaml
soul: SOUL.md
inventory: inventory/hosts.yaml
secrets: config/secrets.env
memory:
  - memory/index.md
  - memory/user-profile.md
```

### Step 6：验证

```bash
# 检查网关
curl http://localhost:8642/health

# 以 observer 身份测试（只读，最安全）
hermes chat --persona observer "当前系统状态如何？"
```

---

## 附录 A：Open WebUI 集成

将 Hermes 作为 OpenAI 兼容 API 接入 Open WebUI：

```
config/config.yaml 中的 platforms.api_server 配置：
  host: "0.0.0.0"
  port: 8642
  cors_origins:
    - "<Open WebUI 地址>"   # 例如 http://localhost:3000

Open WebUI 连接设置：
  API URL: http://<Hermes 主机地址>:8642/v1
  （从 Docker 容器访问宿主机需用 host.docker.internal）

重启命令：
  sudo hermes gateway restart --system
```

---

## 附录 B：Webhook 快速配置

让外部告警/CI/CD 系统自动触发 Agent：

```bash
# 启用 webhook 平台（config/config.yaml 中设置）：
# platforms.webhook.enabled: true
# platforms.webhook.port: 8644
# platforms.webhook.secret: "${WEBHOOK_SECRET}"

# 重启后订阅一个告警 webhook
hermes webhook subscribe ops-alert \
  --prompt "告警: {alert.name}\n级别: {alert.severity}\n详情: {alert.message}\n\n请诊断。" \
  --skills "diagnose,observe" \
  --deliver <你的通知渠道> \
  --deliver-chat-id "<渠道 ID>"

# 测试
hermes webhook test ops-alert --payload '{"alert":{"name":"test","severity":"high","message":"test alert"}}'
```

详见 `skills/integrate/webhook-subscriptions/SKILL.md`。

---

## 常见问题

| 问题 | 解决 |
|------|------|
| `hermes: command not found` | 安装 Hermes CLI，参考官方文档 |
| `Permission denied: /var/log/hermes` | `sudo mkdir -p /var/log/hermes && sudo chmod 755 /var/log/hermes` |
| skill 不响应 | 检查 `memory/index.md` 中的触发词是否匹配 |
| 连接目标服务器失败 | 检查 `inventory/hosts.yaml` 中的 IP 和 `secrets.env` 中的凭据 |
| verify.sh 报告 FAIL | 按提示逐项修复：检查明文密码/SOUL 完整性/frontmatter |
