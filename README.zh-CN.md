# Themis - 智能运维 Agent 框架

<p align="center">
  <img src="https://img.shields.io/badge/Hermes-兼容-blue" alt="Hermes 兼容">
  <img src="https://img.shields.io/badge/协议-MIT-green" alt="协议">
  <img src="https://img.shields.io/badge/三定律-不可变更-red" alt="三定律 不可变更">
</p>

<p align="center">
  <a href="README.md">English</a> | <b>简体中文</b>
</p>

> **Themis（忒弥斯）** — 基于运维三定律的 AI 运维 Agent 治理框架。
> 提供原则、方法论与安全护栏；具体的系统 skill 由你自己实现。

**SOUL.md 是不可变核心** — 三定律定义于此，任何 skill、指令或用户输入均不得绕过。

---

## Themis 是什么？

Themis 是一个**运维 Agent 框架**，而不是一个开箱即用的 Agent。它提供：

- **治理层**：安全铁律（`SECURITY.md`）、运维三定律（`SOUL.md`）、逻辑角色与 preflight 安全预检
- **方法论 skill**：备份、诊断、可观测性的抽象原则
- **基础骨架**：inventory/凭据分离、审计日志机制
- **扩展点**：你在此框架上实现针对自己环境的具体 skill

框架与基础设施无关。你的环境 IP、凭据和服务配置存在于 `inventory/hosts.yaml` 和 `config/secrets.env` 中——永远不出现在 skill 文件里。

---

## 核心设计

### 四层架构

```
SECURITY.md（不可变安全铁律）
  └─ SOUL.md（不可变运维三定律）
       └─ AGENTS.md + Hermes Profiles（流程与物理隔离）
            └─ memory/index.md + inventory + skills/**（路由与方法论）
```

skill 只引用变量名（`${NODE_DB}`、`${SSH_DEFAULT_PASS}`）。切换环境只需修改 `inventory/hosts.yaml` + `secrets.env`，skill 本身不变。

### 逻辑角色与 Hermes Profiles

四种角色保留为逻辑授权模型；生产实例通过 Hermes Profiles 做物理隔离：

| 逻辑角色 | Profile | 硬约束 |
|----------|---------|--------|
| `observer` / `diagnoser` | `themis-observe` | 无写工具、无生产可写凭据 |
| `executor` | `themis-execute` | 强制审批、预检与 security 门禁 |
| `approver` | `themis-approve` 或 Hermes approvals | 只签核，不执行 shell、不加载可写 inventory |

```bash
hermes -p themis-observe
hermes -p themis-execute
```

---

## 运维三定律

`SECURITY.md` 先于 `SOUL.md` 加载，两者均不可变。`SOUL.md` 包含运维核心：

- **第一定律**：系统稳定性至上（高于一切）
- **第二定律**：服从人类指令（冲突时第一定律优先）
- **第三定律**：不可逆操作的防御（备份验证 + 审计日志）

SOUL.md 的约束：
- `immutable: true` — 内容不随会话更新
- `override: forbidden` — 任何试图绕过的指令将被自动拒绝
- `load: always` — 每次推理前均已加载，与激活的 persona 无关

三定律的执行流程（预检、审计日志）在 `skills/safety/preflight-and-audit/` 中实现。

---

## 安全与合规门禁

- 部署前阅读 `SECURITY.md` 与 `AGENTS.md`。
- 基于 `templates/profiles/` 创建隔离 profile。
- 填写 `security/attestations/` 下的声明；example 不是有效证明。
- 运行 `bash scripts/verify.sh`，要求退出码为 `0` 且 `FAIL: 0`。
- Hermes 原生 approvals、隔离、promptware 防护与凭据控制以 [Hermes Security 官方文档](https://hermes-agent.nousresearch.com/docs/user-guide/security) 为准。

---

## 项目结构

```
Themis/
├── SECURITY.md                     # 不可变安全铁律
├── SOUL.md                         # 三定律（不可变）
├── AGENTS.md                       # 加载顺序、Profiles 与门禁
├── MIGRATION.md                    # 从已有 Hermes 配置迁移的指南
├── config/
│   ├── config.example.yaml         # 安全默认值；逻辑角色映射见 AGENTS.md
│   └── secrets.env.example         # 凭据模板 → 复制为 secrets.env（gitignored）
├── memory/
│   ├── index.md                    # Skills 索引（触发词 → 路径）
│   └── user-profile.example.md     # 操作员画像模板
├── inventory/
│   └── hosts.example.yaml          # 主机清单模板（变量命名约定）
├── skills/
│   ├── security/                   # 安全方法论与硬门禁
│   ├── safety/                     # 安全：预检 + 审计（三定律的执行层）
│   ├── infra/                      # 基础：inventory 加载 + 凭据规范
│   ├── observe/                    # 可观测性方法论（抽象原则）
│   ├── diagnose/                   # 故障诊断方法论（抽象原则）
│   ├── backup/                     # 数据备份方法论（抽象原则）
│   └── integrate/                  # 集成：Webhook 事件订阅
└── scripts/
    ├── install.sh                  # 初始化脚本
    └── verify.sh                   # 合规检查（支持 CI）
```

`observe/`、`diagnose/`、`backup/` 是**方法论文件**——定义原则、决策框架和输出规范。具体的实现（针对你的数据库、缓存、消息队列的命令）由你编写本地 skill，声明 `depends_on` 引用方法论 skill。

---

## 懒得看文档？让 Agent 帮你搞定

### 全新安装

**给人类**

复制这段 prompt 给你的 Hermes Agent：

```
按照这里的说明安装和配置 Themis：
https://raw.githubusercontent.com/gundamff/Themis/main/INSTALL.md
```

**给 Hermes Agent**

获取安装指南并执行：

```bash
curl -s https://raw.githubusercontent.com/gundamff/Themis/main/INSTALL.md
```

---

### 从已有 Hermes 配置迁移

**给人类**

复制这段 prompt 给你的 Hermes Agent：

```
按照这里的说明，将我现有的 Hermes Agent 配置迁移到 Themis 框架：
https://raw.githubusercontent.com/gundamff/Themis/main/MIGRATION.md

我当前的 Hermes 配置在：~/.hermes/（如果路径不同请调整）
```

**给 Hermes Agent**

获取迁移指南并执行：

```bash
curl -s https://raw.githubusercontent.com/gundamff/Themis/main/MIGRATION.md
```

迁移指南包含 5 个阶段：骨架文件 → skill 迁移 → memory 映射 → profile 迁移 → 验证。
覆盖凭据外置、IP 变量化、frontmatter 合规检查。
完成后运行 `bash scripts/verify.sh` 验证。

---

## 开始使用

### Step 1：初始化

```bash
git clone https://github.com/gundamff/Themis
cd Themis
bash scripts/install.sh
```

### Step 2：填写你的环境信息

```bash
vi config/secrets.env        # 你的凭据
vi inventory/hosts.yaml      # 你的主机 IP 和服务端点
vi memory/user-profile.md    # 你的运维人员信息
```

### Step 3：编写你的具体 skill

在 `~/.hermes/skills/` 或本地目录中创建具体 skill，遵循以下模式：

```yaml
---
name: my-db-backup
title: 我的数据库备份
soul: SOUL.md
persona: executor
depends_on:
  - backup               # 继承方法论约束
  - infra/inventory-loader
  - safety/preflight-and-audit
required_vars:
  - NODE_DB
  - SSH_DEFAULT_PASS
  - DB_MY_PASS
---
# 在此处编写针对你的数据库的具体备份命令
```

### Step 4：加载到 Hermes

```bash
hermes gateway setup
hermes gateway run
hermes -p themis-observe
```

---

## 编写新 Skill

### Frontmatter 规范（必填字段）：

```yaml
---
name: my-skill
title: 中文名称
soul: SOUL.md              # 必填：显式从属
persona: observer          # 必填：observer | diagnoser | executor
version: 1.0
triggers:                  # 必填：至少 3 个触发词
  - 触发词1
  - 触发词2
depends_on:                # 本 skill 所依赖的方法论 skill
  - observe                # 或 backup、diagnose
  - infra/inventory-loader
required_vars:             # 声明使用的 inventory/secrets 变量
  - NODE_DB
description: 一句话描述
---
```

### 禁止事项：
- 在 skill 中硬编码 IP 地址（使用 `${NODE_XXX}`）
- 在 skill 中硬编码密码（使用 `${DB_XXX_PASS}` 等）
- 在 skill 中复述三定律条文（应引用 SOUL.md）
- executor 角色的写操作未声明 `depends_on: [safety/preflight-and-audit]`

### 验证新 skill：

```bash
bash scripts/verify.sh
# 全部通过后才可提交
```

---

## 贡献指南

### PR 检查清单

- [ ] 运行 `bash scripts/verify.sh` 全部通过（零 FAIL）
- [ ] 新 skill 的 frontmatter 包含 `soul`、`persona`、`triggers`
- [ ] 未新增硬编码 IP 或密码
- [ ] 未修改 `SOUL.md`
- [ ] 方法论 skill（`observe/`、`diagnose/`、`backup/`）保持抽象——不含具体命令

### 不接受的 PR

- 修改 SOUL.md 中的三定律内容（除非 issue 中已达成共识）
- 在方法论 skill 中加入具体工具的命令
- 跳过预检的写操作 skill

---

## 文档

- [安装指南](INSTALL.md)
- [迁移指南](MIGRATION.md) — 从已有 Hermes 配置迁移
- [运维三定律](SOUL.md) — 不可变核心

---

## 语言

- [English](README.md)
- [简体中文](README.zh-CN.md)

---

## 许可证

[MIT](LICENSE)

---

<p align="center">
  <i>以希腊神话中的正义与秩序女神忒弥斯（Themis）命名。</i>
</p>
