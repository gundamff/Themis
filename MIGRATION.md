# MIGRATION.md — 已有 Hermes Agent 改造指南

> 适用对象：你本地已运行一段时间的旧版 Hermes Agent 配置。
> 目标：迁移到 Themis 的目录结构，引入三定律、凭据外置、skills 分层。

---

## 迁移总览


| 操作阶段    | 内容                                    | 顺序              |
| ------- | ------------------------------------- | --------------- |
| Phase 1 | 新建骨架文件（SOUL/config/inventory/secrets） | 先做，是后续操作的基础     |
| Phase 2 | skills 迁移与变量化                         | 逐文件处理           |
| Phase 3 | memory 精简                             | 最后清理旧 README.md |
| Phase 4 | 验证                                    | 全部完成后           |


---

## Phase 1：新建骨架文件

### 1.1 创建 SOUL.md

从 `Themis/SOUL.md` 复制到你的 Hermes 根目录（通常 `~/.hermes/` 或 Hermes 项目目录）：

```bash
cp Themis/SOUL.md ~/.hermes/SOUL.md
```

**验证**：确认包含三定律且 frontmatter 有 `immutable: true`：

```bash
grep -E "immutable:|第一定律|第二定律|第三定律" ~/.hermes/SOUL.md && echo OK || echo FAIL
```

### 1.2 创建凭据文件

**绝对不要提交到 Git。**

```bash
cp Themis/config/secrets.env.example ~/.hermes/config/secrets.env
# 然后编辑填写实际值
vi ~/.hermes/config/secrets.env
```

立即加入 `.gitignore`：

```bash
echo "config/secrets.env" >> ~/.hermes/.gitignore
echo "inventory/hosts.yaml" >> ~/.hermes/.gitignore
```

**验证**：

```bash
grep 'secrets.env' ~/.hermes/.gitignore && echo OK || echo FAIL
```

### 1.3 创建 `inventory/hosts.yaml`（你的专属清单）

这份文件保留你环境的具体 IP，不开源，只在本地使用：

```bash
mkdir -p ~/.hermes/inventory
cp Themis/inventory/hosts.example.yaml ~/.hermes/inventory/hosts.yaml
# 然后编辑，将 <NODE_X_IP> 替换为实际 IP，按你的服务补充 services 段
vi ~/.hermes/inventory/hosts.yaml
```

### 1.4 更新 config.yaml

将以下字段合并入现有 `config.yaml`（保留原有 platforms 配置不变）：

```yaml
soul: ~/.hermes/SOUL.md
inventory: ~/.hermes/inventory/hosts.yaml
secrets: ~/.hermes/config/secrets.env
memory:
  - ~/.hermes/memory/index.md
  - ~/.hermes/memory/user-profile.md
```

**验证**：

```bash
grep -E "soul:|inventory:|secrets:" ~/.hermes/config.yaml && echo OK
```

---

## Phase 2：Skills 逐文件迁移

### 文件决策原则

对旧 skills 中的每个文件，按以下决策树处理：

1. **含三定律条文** → 删除条文，改为 `soul: SOUL.md` 引用
2. **含硬编码 IP** → 替换为 `${NODE_XXX}` 变量，在 inventory 中定义
3. **含硬编码密码/用户名** → 替换为 `${VAR_NAME}` 变量，在 secrets.env 中定义
4. **含业务特定的表名/topic/集合名** → 作为变量放入 inventory 的业务配置段
5. **含用户姓名/联系方式** → 迁移到 `memory/user-profile.md`，从 skill 中删除

### 执行变量替换的通用方法

对每个迁移后的 SKILL.md，执行以下类型的替换（以你自己的旧值为准）：

```bash
SKILL_FILE="skills/xxx/SKILL.md"

# SSH 凭据（替换你旧配置中的实际用户名和密码）
sed -i "s/旧SSH用户名/\${SSH_DEFAULT_USER}/g" "$SKILL_FILE"
sed -i "s/旧SSH密码/\${SSH_DEFAULT_PASS}/g" "$SKILL_FILE"

# 数据库密码（替换你旧配置中的实际密码）
sed -i "s/旧数据库密码/\${DB_<产品名>_PASS}/g" "$SKILL_FILE"

# IP 地址（替换你旧配置中的实际 IP）
sed -i "s/<旧NODE1_IP>/\${NODE_CONTROL}/g" "$SKILL_FILE"
sed -i "s/<旧NODE2_IP>/\${NODE_APP}/g" "$SKILL_FILE"
# ... 以此类推
```

**验证每个文件**（用你旧配置的实际值替换下面的占位符）：

```bash
grep -n '<旧SSH密码>\|<旧数据库密码>\|<旧IP地址>' "$SKILL_FILE" \
  && echo "FAIL: 仍有硬编码" || echo "OK: 无明文凭据"
```

**迁移后全量验证**：

```bash
# 在 skills/ 中搜索任何看起来像密码或 IP 的内容
bash scripts/verify.sh
```

### 迁移后必须添加的 frontmatter 字段

每个 SKILL.md 顶部必须包含：

```yaml
---
name: <skill 唯一标识>
title: <可读名称>
soul: SOUL.md           # 必填
persona: <observer|diagnoser|executor>  # 必填
version: 1.0
triggers:               # 必填，至少 3 个
  - <触发词1>
  - <触发词2>
  - <触发词3>
depends_on:             # 如有依赖
  - infra/inventory-loader
required_vars:          # 声明使用的变量名
  - <VAR_NAME>
description: <一句话描述>
---
```

---

## Phase 3：Memory 精简

### 3.1 旧 README.md 各段落去向


| 段落内容                 | 去向                           |
| -------------------- | ---------------------------- |
| 三定律/运维法则             | 删除（已移入 SOUL.md）              |
| 平台配置要点（Open WebUI 等） | 保留在 INSTALL.md 附录            |
| 机器清单（IP、服务器列表）       | 删除（已移入 inventory/hosts.yaml） |
| 备份方案表                | 删除（已抽象为 skills/backup 方法论）   |
| 数据关联规则（业务 schema 信息） | 移入本地 inventory 的业务配置段        |
| 故障经验记录               | 可保留在本地 skill 的"注意事项"中，但业务名脱敏 |
| 用户画像（负责人姓名、授权范围）     | 移入 memory/user-profile.md    |


### 3.2 创建 memory/user-profile.md

```bash
cp Themis/memory/user-profile.example.md ~/.hermes/memory/user-profile.md
# 填写实际的负责人、授权范围、沟通偏好
vi ~/.hermes/memory/user-profile.md
```

### 3.3 更新 memory/index.md

```bash
cp Themis/memory/index.md ~/.hermes/memory/index.md
# 如有本地自定义 skill，在 index.md 中追加触发词映射
```

---

## Phase 4：验证

### 4.1 合规检查（推荐先运行）

```bash
bash scripts/verify.sh
# 全部 OK，无 FAIL 项
```

### 4.2 三定律重复检查

```bash
# skills/ 中不应有三定律条文（只有 SOUL.md 是权威来源）
grep -rln "第一定律\|第二定律\|第三定律" skills/
# 期望：无输出
```

### 4.3 明文凭据检查

```bash
# skills/ 和 memory/ 中不应有真实密码或真实 IP
# 用你旧配置中已知的密码/IP 做检查：
grep -rn '<你的旧密码>\|<你的旧IP>' skills/ memory/ \
  && echo "FAIL: 仍有明文凭据" || echo "OK"
```

### 4.4 Skill frontmatter 检查

```bash
for f in $(find skills/ -name "SKILL.md"); do
  grep -q "soul:" "$f" || echo "MISSING soul: $f"
  grep -q "persona:" "$f" || echo "MISSING persona: $f"
  grep -q "triggers:" "$f" || echo "MISSING triggers: $f"
done
```

---

## 迁移后目录结构（最终形态）

```
~/.hermes/
├── SOUL.md                          # 从 Themis 复制，不可修改
├── config/
│   ├── config.yaml                  # 含 soul/inventory/secrets/4-persona 配置
│   └── secrets.env                  # [gitignored] 你的真实凭据
├── memory/
│   ├── index.md                     # skills 触发词索引
│   └── user-profile.md              # 你的运维人员信息
├── inventory/
│   └── hosts.yaml                   # [gitignored] 你的机器清单（含实际 IP）
└── skills/
    ├── safety/preflight-and-audit/  # 来自 Themis，方法论层
    ├── infra/inventory-loader/      # 来自 Themis，方法论层
    ├── infra/credentials/           # 来自 Themis，方法论层
    ├── observe/                     # 来自 Themis（方法论）+ 本地具体实现
    ├── diagnose/                    # 来自 Themis（方法论）+ 本地具体实现
    ├── backup/                      # 来自 Themis（方法论）+ 本地具体实现
    └── integrate/webhook-subscriptions/  # 来自 Themis，可直接使用
```

---

## 注意事项

1. `inventory/hosts.yaml` 含实际 IP，不要上传到公开代码仓库
2. `secrets.env` 含真实凭据，即使在私有仓库也不要提交
3. 迁移时 Hermes 不需要停机，skill 文件修改后下次会话自动生效
4. 旧 skills 目录可以先保留，全部迁移验证通过后再删除
5. 本地具体 skill 可以随时扩展，不影响 Themis 框架本身的方法论层

