# Profile: `themis-observe`

只读 Hermes profile，承载 **observer** / **diagnoser**：巡检与诊断，**不得**变更生产状态。

## Hermes 原生硬约束（已写入 `config.snippet.yaml`）

| 键 | 作用 |
|----|------|
| `agent.disabled_toolsets` | 禁用 `code_execution`、`browser`、`web`、`computer_use`、`delegation`、`cronjob` 等 |
| `approvals.deny` | 破坏性命令硬否决（YOLO 也无法绕过） |
| `terminal.backend: docker` | 命令进容器；`docker_forward_env: []` 默认不注入密钥 |

## 额外强烈建议（profile `.env`）

```bash
# 将 write_file/patch 限制在空沙箱前缀（按官方 HERMES_WRITE_SAFE_ROOT）
HERMES_WRITE_SAFE_ROOT=/tmp/themis-observe-writes-blocked
# 禁止 YOLO
# 不要设置 HERMES_YOLO_MODE=1
# 网关用户 allowlist（若启用 messaging）
GATEWAY_ALLOWED_USERS=your_id
```

## 安装

1. `hermes profile create themis-observe`（或拷贝到 `$HERMES_HOME/profiles/themis-observe`）
2. 合并 `config.snippet.yaml` → profile `config.yaml`
3. 拷贝仓库根 `SOUL.md`、`SECURITY.md`、`AGENTS.md` 到 profile home
4. 配置 `.env` 如上；**不要**挂载可写生产 secrets
5. `bash scripts/verify.sh`

## 切换

```bash
hermes -p themis-observe
```
