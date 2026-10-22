---
name: inventory-loader
title: 基础设施清单加载器
soul: SOUL.md
persona: observer, diagnoser, executor
version: 1.0
triggers:
  - 机器清单
  - 服务器列表
  - 主机信息
  - 查看节点
  - inventory
  - hosts
required_vars: []
description: >
  从 inventory/hosts.yaml 读取基础设施清单，供其他 skill 引用主机别名和服务端点。
  不含任何凭据，凭据由 config/secrets.env 在运行时注入。
---

# 基础设施清单加载器

## 用途

本 skill 是所有需要访问主机的 skill 的前置依赖。
skill 脚本中的 `${NODE_XXX}` 变量在此处被解析为 inventory 中定义的实际值。

在需要主机信息的 skill 中，顶部声明：

```yaml
depends_on:
  - infra/inventory-loader
```

Agent 会在执行该 skill 前自动加载 `inventory/hosts.yaml`，使变量可用。

---

## inventory 的职责

`inventory/hosts.yaml` 是环境与 skill 之间的唯一隔离层：

- 存储主机别名（alias）与实际 IP 的映射
- 存储服务端点、端口、路径等环境相关配置
- **不存储任何凭据**（凭据在 `config/secrets.env`）
- **不存储任何业务逻辑**（业务逻辑在 skill 中）

当切换到新环境时，只需修改 `inventory/hosts.yaml`，skill 代码保持不变。

---

## 变量命名约定

主机别名使用 `NODE_` 前缀，服务端点使用语义化前缀：

```
NODE_<角色>       —— 主机节点 IP，例如 NODE_CONTROL, NODE_DB, NODE_APP
<SERVICE>_HOST    —— 服务主机，例如 KAFKA_HOST, MONGO_HOST
<SERVICE>_PORT    —— 服务端口，例如 REDIS_PORT, OB_PORT
<SERVICE>_<用途>  —— 其他服务相关路径，例如 KAFKA_DATA_DIR
```

具体的变量名由使用者根据自身环境在 `inventory/hosts.yaml` 中定义。
所有 skill 脚本中只引用变量名（`${NODE_DB}`），不硬编码实际 IP 或路径。

---

## 加载时机

- 每次会话中，Agent 在执行任意依赖本 skill 的操作前自动加载
- 修改 `hosts.yaml` 后无需重启 Agent，下次调用时自动重新加载
- 若 `hosts.yaml` 不存在，Agent 将提示使用者从 `hosts.example.yaml` 模板初始化

---

## 快速查看当前清单

```bash
cat inventory/hosts.yaml
```

---

## 注意事项

- 本 skill 不暴露密码，凭据变量（如 `${SSH_DEFAULT_PASS}`）由 `config/secrets.env` 提供
- 如果某个 skill 需要某个变量但 inventory 中未定义，执行前会报 `required_vars` 缺失错误
- inventory 示例模板见 `inventory/hosts.example.yaml`，包含节点结构和变量命名约定
