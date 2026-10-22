# Themis P1 — 运行时完整性设计

**日期：** 2026-10-22  
**状态：** 已确认并实施  
**范围：** 对照表 §7 条目 5–9（用户选定 **方案 A：全做**）  
**分支：** `feat/hermes-security-hardening`（可同分支续提；或切 `feat/p1-runtime-integrity`）  
**前置：** P0 + 方案 C 已落地（`bbd2e5b`）

---

## 1. 目标与非目标

### 1.1 目标

在 P0「大门关闭」之上，补齐审批不可偷换、MCP 供应链可控、对抗可回归、输出/审计可观测、容器边界不被 privileged 挖空。交付形态与 P0 一致：**条文 + 模板 + `verify.sh` 门禁 + attestation**；Hermes 内核没有的能力写成**强制规程**，不伪造运行时钩子。

### 1.2 非目标

- 不实现独立审批微服务 / 不 fork Hermes
- 不把 Elkeid/vArmor/GShark 做成 Themis 内置（属 P2 EXT）
- 不改 SOUL 三定律语义；SECURITY 仅在需要时增加短交叉引用（不扩成手册）
- 不做多 Agent / peer 信任专章（P2）

### 1.3 Linus 三问

1. **真问题：** 对照表明确 N/P；注入成功后仍可偷换命令、装 MCP、吐密钥。  
2. **更笨的路：** 只写散文 → 已否定；用 artifact 约定 + 静态/对抗门禁即可。  
3. **破坏谁：** 仅增加 skill/模板/CI 要求；旧部署须补填 attestation，行为默认更严。

---

## 2. 推荐落地形态（已选）

| 方案 | 描述 | 取舍 |
|------|------|------|
| **A（本设计）** | 仓库内规程 + schema + verify 门禁 + 轻量对抗脚本 | 与 P0 一致；不假装有 Hermes 中间件 |
| B | 等 Hermes 原生审批票据 API 再做 | 正确但无限期推迟 |
| C | 外挂 OPA/策略引擎 | 过重，超出 Themis 定位 |

**实施顺序：** 9 → 5 → 6 → 8 → 7（逃逸专条最快；对抗依赖前序控制）。

---

## 3. 分项设计

### 3.1 项 9 — 容器逃逸 / privileged pod（CDK）

**改动：**

- 扩展 `skills/security/privileged-plane/SKILL.md`（+ `.en.md`）：新增「Agent / 沙箱工作负载」专节  
  - 禁止：`privileged: true`、挂载 docker.sock、hostNetwork/hostPID（无书面例外）  
  - 要求：非 root 或明确 capability 裁剪；只读根 FS 偏好；生产 Hermes `terminal.backend=docker` 镜像非 privileged  
  - 交叉引用：容器 ≠ 业务变更免审（已有 AGENTS 警告）  
- 新增 `security/attestations/sandbox-not-privileged.example.md`  
- `verify.sh`：`SEC-SANDBOX` — attestation 模板存在；privileged-plane 含「privileged」/「docker.sock」关键词  

**完成定义：** 集权面 skill 可指导审查 Agent 沙箱；CI 缺模板则 FAIL。

---

### 3.2 项 5 — 审批完整性（OA-1.4 / OA-4.4）

**核心数据结构 — Approval Ticket（规程级，非新服务）：**

```yaml
# security/schemas/approval-ticket.example.yaml
ticket_id: "<uuid>"
trace_id: "<uuid>"          # 与 preflight 一致
actor: "approver-id-or-role"
tool: "terminal|kubectl|..." # 逻辑工具名
argv_digest: "sha256:..."    # 对规范化命令/参数的哈希
scope: "<target abstract>"
risk_level: high|critical
issued_at: "<ISO8601>"
expires_at: "<ISO8601>"      # 建议 ≤ 30m（与现 preflight 超时对齐）
nonce: "<random>"
consumed: false
step_up_mfa: true|false      # critical 须 true（attestation/规程）
```

**改动：**

- `skills/safety/preflight-and-audit/SKILL.md`：  
  - Step 3 产出必须含 `argv_digest` / `expires_at` / `nonce`  
  - Step 5 执行前校验：票据未过期、未消费、digest 与将执行命令一致；否则 **阻断**  
  - 明确：容器后端跳过 Hermes 危险命令提示时，**仍须**有效票据  
- 审计 JSON 增加可选字段：`approval_ticket_id`、`argv_digest`  
- `AGENTS.md`：执行面必须携带可验证票据语义  
- `verify.sh`：`SEC-TICKET` — schema 示例存在；preflight skill 含 `argv_digest` 与 `expires_at`  

**完成定义：** 文档与 skill 禁止「口头批准另一条命令」；静态门禁可证明字段存在。  
**诚实边界：** 若 Hermes 不强制校验 digest，运行时仍靠 Agent 遵守 skill；对抗测试（项 7）覆盖「偷换参数应拒绝」的规程用例。

---

### 3.3 项 6 — MCP 供应链（DS-MCP*）

**改动：**

- 新增 `security/mcp-allowlist.example.yaml`：

```yaml
# 生产仅允许下列 MCP；禁止会话内临时安装；禁止 @latest
servers:
  - name: example-readonly
    version: "1.2.3"          # 钉死；或 integrity: sha256:...
    purpose: "..."
    owner: "<role>"
    last_reviewed: "<ISO8601>"
policy:
  allow_ad_hoc_install: false
  allow_latest_tag: false
  require_redescribe_review: true  # 工具描述变更须重审
```

- 新增 `skills/security/mcp-supply-chain/SKILL.md`（+ `.en.md`）：批准清单、钉版、描述变更重审、凭据过滤须开启（指向 Hermes）  
- attestation：`security/attestations/mcp-allowlist.example.md`（声明已按清单部署）  
- `AGENTS.md` + `config.example.yaml` 注释：生产 MCP 须 allowlist  
- `verify.sh`：`SEC-MCP` — allowlist 模板 + skill 存在；模板中无 `@latest` 作为允许策略  

**完成定义：** 仓库有可填写的 MCP 批准面；CI 缺 skill/模板 FAIL。

---

### 3.4 项 8 — 输出脱敏与 tool 审计指标（OA-5/6）

**改动：**

- 新增 `skills/security/output-and-audit-guards/SKILL.md`（+ `.en.md`）：  
  - 输出：禁止回显可复用密钥；tool 结果脱敏规则；大包/webhook URL 外泄模式告警意向  
  - 审计：全量 tool 调用字段最低集；日志脱敏；异常指标（无票据执行尝试、单位时间高危命令、异常目的地）  
- 扩展 preflight 审计 schema 文档，与项 5 字段对齐  
- `security/schemas/audit-tool-event.example.json`  
- `verify.sh`：`SEC-OUTPUT` — skill 存在；示例 schema 含 `tool_name` 与脱敏相关关键词  

**完成定义：** 有可执行的输出/审计方法论；不声称 Hermes 已内置输出过滤器。

---

### 3.5 项 7 — 对抗测试矩阵进 CI（OA-9）

**改动：**

- 新增 `tests/adversarial/cases.md` — 用例表（注入关防护、YOLO、observe 调 browser、偷换 argv、临时 MCP、privileged 挂载等）  
- 新增 `scripts/verify-adversarial.sh`：  
  - **静态对抗**：对仓库文件做负向断言（例如 config 不得 `mode: off`；observe snippet 必须禁 browser；allowlist `allow_ad_hoc_install: false`；preflight 含票据字段）  
  - **规程对抗**：`cases.md` 中每条标明 expected=`blocked`，脚本检查对应证据文件存在  
- `scripts/verify.sh` 末尾可选调用或文档要求 CI 跑两者；本设计：**verify.sh 增加对 verify-adversarial.sh 的调用**（失败则 FAIL）  
- `verify.sh`：`SEC-ADV` — adversarial script + cases 存在且脚本退出 0  

**完成定义：** CI 一条命令可跑静态+规程对抗；不是模型 live 红队（那是后续增强）。

---

## 4. 文件清单（预计）

| 路径 | 动作 |
|------|------|
| `skills/security/privileged-plane/SKILL.md` (+en) | 改 |
| `skills/safety/preflight-and-audit/SKILL.md` (+en) | 改 |
| `skills/security/mcp-supply-chain/SKILL.md` (+en) | 增 |
| `skills/security/output-and-audit-guards/SKILL.md` (+en) | 增 |
| `security/schemas/approval-ticket.example.yaml` | 增 |
| `security/schemas/audit-tool-event.example.json` | 增 |
| `security/mcp-allowlist.example.yaml` | 增 |
| `security/attestations/sandbox-not-privileged.example.md` | 增 |
| `security/attestations/mcp-allowlist.example.md` | 增 |
| `tests/adversarial/cases.md` | 增 |
| `scripts/verify-adversarial.sh` | 增 |
| `scripts/verify.sh` | 改（SEC-SANDBOX/TICKET/MCP/OUTPUT/ADV） |
| `AGENTS.md` | 改（短节） |
| `config/config.example.yaml` | 改（MCP/票据注释） |
| `docs/superpowers/specs/2026-10-22-security-external-crosswalk.md` | 改（P1 状态） |

可选：`SECURITY.md` 增加一句「高危变更须可验证审批票据」指向 preflight（保持短铁律，不写手册）。

---

## 5. 门禁 ID 汇总

| ID | 意图 |
|----|------|
| `SEC-SANDBOX` | 沙箱非 privileged 条文 + attestation |
| `SEC-TICKET` | 审批票据 schema + preflight 字段 |
| `SEC-MCP` | MCP allowlist + skill |
| `SEC-OUTPUT` | 输出/审计 skill + schema |
| `SEC-ADV` | 对抗脚本与用例通过 |

成功标准：`bash scripts/verify.sh` → `FAIL: 0`。

---

## 6. 风险与诚实声明

- **审批票据**在 Hermes 无强制中间件时，是**规程 + 对抗静态检查**，不是密码学强制。PR/文档必须写明。  
- **对抗测试**首版不调用真实 LLM；防的是「仓库回退到不安全默认」与「规程文件被删」。  
- 英文 skill 与中文同步，避免只改一侧。

---

## 7. 确认清单

- [x] 范围 A（5–9）无删减  
- [x] 落地形态：规程 + 模板 + verify（不造审批服务）  
- [x] 对抗首版：静态/规程，非 live 红队  
- [x] 同分支 `feat/hermes-security-hardening` 续做  

计划：`docs/superpowers/plans/2026-10-22-themis-p1-runtime-integrity.md`。
