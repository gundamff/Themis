# Profile: `themis-execute`

可写执行 profile：**executor**。变更须审批 + preflight；生产禁 YOLO。

## Hermes 原生硬约束

| 键 | 作用 |
|----|------|
| `approvals.mode: smart` | 禁止 `off` |
| `approvals.deny` | 高危模式硬否决 |
| `terminal.backend: docker` | 容器隔离；注意容器内危险命令审批可能被跳过，**业务变更仍须 preflight** |
| `docker_forward_env: []` | 默认不向容器灌密钥 |

## `.env` 红线

```bash
# 禁止：
# HERMES_YOLO_MODE=1
# GATEWAY_ALLOW_ALL_USERS=true
# 必须：配置 GATEWAY_ALLOWED_USERS 或平台 *_ALLOWED_USERS
```

## 安装

1. `hermes profile create themis-execute`
2. 合并 `config.snippet.yaml`
3. 拷贝 `SOUL.md`、`SECURITY.md`、`AGENTS.md`
4. 填写 secrets；执行技能须 `depends_on: safety/preflight-and-audit`
5. `bash scripts/verify.sh`

```bash
hermes -p themis-execute
```
