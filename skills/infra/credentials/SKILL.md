---
name: credentials
title: 凭据使用规范
soul: SOUL.md
persona: executor
version: 1.0
triggers:
  - 凭据
  - 密码
  - 连接信息
  - credentials
  - secrets
required_vars: []
description: >
  凭据的加载机制和使用规范，不存储任何实际密码。
  真实凭据在 config/secrets.env 中，已加入 .gitignore。
---

# 凭据使用规范

## 架构原则

```
config/secrets.env  (真实值，永不提交到 Git)
        ↓ 运行时注入
skill 脚本中的 ${VAR_NAME}  (占位符，可以提交)
        ↓ shell 展开
实际命令中的具体值
```

任何 skill 文件（包括 `.md`、`.sh`、`.py`）中，凭据只能以变量引用形式出现，不得出现实际值。

---

## 凭据变量命名约定

按所属系统类型分组，遵循以下前缀规则：

| 前缀 | 适用范围 | 示例变量名 |
|------|----------|-----------|
| `SSH_` | SSH 登录凭据 | `SSH_DEFAULT_USER`, `SSH_DEFAULT_PASS` |
| `DB_` | 数据库凭据 | `DB_<产品名>_USER`, `DB_<产品名>_PASS` |
| `CACHE_` | 缓存服务凭据 | `CACHE_<产品名>_PASS` |
| `MQ_` | 消息队列凭据 | `MQ_<产品名>_USER`, `MQ_<产品名>_PASS` |
| `MON_` | 监控系统凭据 | `MON_<产品名>_USER`, `MON_<产品名>_PASS` |
| `WEBHOOK_` | Webhook 密钥 | `WEBHOOK_SECRET` |
| `STORAGE_` | 对象存储凭据 | `STORAGE_<产品名>_ACCESS_KEY` |

具体变量名由使用者根据自身技术栈在 `config/secrets.env` 中定义，
并在使用这些凭据的 skill 的 `required_vars` 中声明。

---

## 在 skill 脚本中的正确写法

```bash
# 正确：引用变量，值在运行时注入
ssh ${SSH_DEFAULT_USER}@${NODE_DB} "命令"

# 错误：硬编码凭据（会被 scripts/verify.sh 检测并阻止提交）
ssh admin@192.168.1.10 "命令"
```

---

## .gitignore 必须包含

```
config/secrets.env
inventory/hosts.yaml
*.env
!*.env.example
```

`scripts/install.sh` 初始化时会自动确保这些条目存在。

---

## 凭据模板

`config/secrets.env.example` 是凭据文件的模板，包含命名约定和分组说明，值均为空或占位符。
使用者运行 `bash scripts/install.sh` 后，会自动将其复制为 `config/secrets.env`，然后填写实际值。

凭据模板本身可以提交到 Git，实际凭据文件（`secrets.env`）绝对不可提交。
