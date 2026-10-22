# Themis 安全方案 × 外部基线慢对照勾选表

**日期：** 2026-10-22  
**方法：** 代理 `127.0.0.1:7890` 拉取原文 → 清洗为文本 → 按控制项勾选 Themis 证据路径  
**覆盖标记：**
- **Y** = Themis 仓库内有明确条文/模板/检查，且路径可指
- **P** = 部分覆盖（仅政策/文档/依赖 Hermes，无运行时强制或证据不足）
- **N** = Themis 缺失
- **EXT** = 明确应外挂工具/平台，不必自研进 Themis 内核

**不做的事：** 不给虚假「完整度百分比」；不把未读到正文的来源算进勾选依据。

---

## 0. 本次实际读到的资料清单

| # | 来源 | 本地产物 | 阅读深度 | 用作勾选？ |
|---|------|----------|----------|------------|
| 1 | OWASP AI Agent Security Cheat Sheet | `ext-security-research/owasp-ai-agent.clean.txt`（~25KB 正文） | **全文精读**九大 Best Practices + Do/Don't + Key Risks | **是** |
| 2 | OWASP DevSecOps — AI Agent and MCP Security | `owasp-devsecops-mcp.clean.txt`（~10KB） | **全文精读**（威胁模型、身份、沙箱、MCP、HITL、审计、成熟度） | **是** |
| 3 | Hermes Agent Security 官方页 | `hermes-security.clean.txt`（~60KB） | **精读**八层总览 + approvals/YOLO/deny/容器绕过等关键段；其余章节抽样 | **是** |
| 4 | OWASP Top 10 for LLM Applications 2026 | `owasp-llm-top10-2026.fetched.txt`（WebFetch 可读文本） | **精读** LLM01–05、lethal trifecta、与 ASI 映射表；06–10 抽样标题与缓解要点 | **是** |
| 5 | OWASP Securing Agentic Applications Guide | `owasp-agentic-guide.fetched.txt` | **抽样**（此前 WebFetch）；本次未再全文通读 → **不作独立勾选源**，仅交叉参考 ASI 编号 | **否（独立源）** |
| 6 | knownsec/404StarLink | README、allprojects、party_a、intranet、vuln + detail：linglong/gshark/Elkeid/vArmor/afrog/fscan/CDK/CyberStrikeAI/agentic-soc/murphysec | **索引全读 + 10 个 detail 打开阅读** | **是（威胁面校验）** |
| 7 | 现场渗透报告（四 PDF） | 此前扫描页视觉分析 | **目录/综述/整改页**；非 OCR 全文 | **是（现场威胁）** |
| 8 | Themis 本仓库 | SECURITY/AGENTS/skills/security/*、verify.sh、config、profiles、attestations | **对照证据源** | **是** |

**明确失败/未用：**
- `genai.owasp.org` 直接 PDF 下载 → 仅 146 字节（无效）
- CISA PDF URL → HTML 壳，**未用**
- DevSecOps raw.githubusercontent 路径 → 404，改用 GitHub Pages 成功

---

## 1. OWASP AI Agent Cheat Sheet（逐条）

| ID | 外部控制项 | Themis 证据 | 覆盖 | 缺口说明 |
|----|------------|-------------|------|----------|
| OA-1.1 | 最小工具集 / per-tool 权限 | `templates/profiles/themis-observe|execute`；`SECURITY.md` §5 | **P** | 意向字段 `deny_tools` **未证明**被 Hermes 执行 |
| OA-1.2 | 不同信任级分离工具集 | observe / execute / approve profiles | **P** | 物理 profile 分离有；工具 allowlist 运行时未钉死 |
| OA-1.3 | 敏感操作显式授权 | `approvals.mode: smart`；`safety/preflight`；SEC-APPROVALS | **Y/P** | 有审批门禁；缺「执行组件独立于 Agent 再校验」 |
| OA-1.4 | 审批绑定 actor+工具+参数+一次性消费 | preflight 报告含 trace_id | **N** | 无参数绑定/一次性/过期 artifact |
| OA-1.5 | 未知工具 fail-closed | — | **N** | 未写 |
| OA-2.1 | 外部数据一律不可信 | AGENTS/Hermes promptware；禁关扫描 | **P** | 依赖 Hermes；缺 Themis 操作规程专节 |
| OA-2.2 | 指令与数据分界 / 过滤 | 依赖 Hermes context scan | **P** | |
| OA-3.1 | Memory 校验/脱敏后再持久化 | — | **N** | |
| OA-3.2 | 用户/会话 memory 隔离 | Hermes profiles/sessions（文档指向） | **P** | Themis 未加策略条文 |
| OA-3.3 | Memory TTL / 完整性校验 | — | **N** | |
| OA-4.1 | 高影响动作人工审批 | approvals + preflight + SEC-APPROVALS | **Y** | |
| OA-4.2 | 动作预览 / 风险分级 | preflight 报告格式；高危词表 | **P** | 无统一 RiskLevel 枚举进配置 |
| OA-4.3 | 可中断/回滚 | SOUL 备份要求；backup skill | **P** | 偏运维回滚，非 Agent 会话中断协议 |
| OA-4.4 | 决策与执行分离 + step-up auth | approver persona；MFA attestation | **P** | MFA 仅声明；无 step-up 运行时 |
| OA-5.1 | 输出结构化校验 / 禁敏感参数 | — | **N** | |
| OA-5.2 | 输出 PII/密钥过滤 | verify 扫 skills 明文；缺运行时 | **P** | |
| OA-5.3 | 外泄模式检测（URL/webhook 大包） | — | **N** | |
| OA-5.4 | 速率限制 / DoW | — | **N** | |
| OA-6.1 | 记录工具调用与结果 | audit.jsonl 设计（safety） | **P** | 模板有；未强制 Hermes 全量 tool log |
| OA-6.2 | 异常：审批绕过、高危频率 | — | **N** | |
| OA-6.3 | 日志脱敏 | credentials skill 禁止明文 | **P** | 无日志管道规范 |
| OA-7.1 | 多 Agent 信任边界 | — | **N** | Hermes peer 未覆盖 |
| OA-7.2 | 链上权限不升级 / 熔断 | incident-response 有熔断意向 | **P** | |
| OA-8.1 | 数据分级与上下文最小化 | — | **N** | |
| OA-8.2 | 静态密钥不进上下文 | SECURITY §2；credentials-hygiene | **Y** | |
| OA-9.1 | 滥用用例矩阵（注入/工具/提权/投毒/外泄/审批绕过） | 仅 SECURITY 缺失 / approvals off 负例 | **P** | 远未达 OWASP 矩阵 |
| OA-9.2 | CI 对抗回归门禁 | `verify.sh` 静态 SEC-* | **P** | 静态≠对抗 |

**Cheat Sheet 小结：** HITL、密钥、读写隔离政策 **相对齐**；工具中间件强制、输出护栏、memory、多 Agent、对抗矩阵 **明显不足**。

---

## 2. OWASP DevSecOps Agent+MCP（逐条）

| ID | 外部控制项 | Themis | 覆盖 |
|----|------------|--------|------|
| DS-T | Lethal trifecta 显式建模（私有数据+不可信内容+外联） | threat-model 有攻击链；**无 egress 腿** | **P** |
| DS-I1 | Agent 独立身份（非复用个人凭据） | profiles 分离；未强制服务账号/OIDC | **P** |
| DS-I2 | 短时、任务级令牌；禁长效生产凭据进环境 | secrets-provider attestation；未禁止长效 | **P** |
| DS-I3 | 假定 .env/环境可被注入后读走 | SECURITY §2；credentials | **Y/P** | 有禁明文；缺「环境即泄露面」专条 |
| DS-I4 | 身份不得进管理员角色；读写身份分离 | SECURITY §5；profiles | **Y** | 政策 Y；强制 P |
| DS-P1 | 默认拒绝 + 显式 allow | observe deny 意向；execute 宽 | **P** |
| DS-P2 | 权限配置进版本库可审 | config.example + templates 进库 | **Y** |
| DS-S1 | 沙箱/容器隔离是边界，审批提示不是 | AGENTS「profile≠沙箱」 | **P** | 有诚实说明；生产未默认 docker |
| DS-S2 | **Egress allowlist** | — | **N** |
| DS-S3 | 禁 skip-permissions / YOLO 于生产 | 禁 approvals off；**未禁 YOLO/HERMES_YOLO** | **P** |
| DS-INJ | 不依赖模型发现注入；靠权限+隔离+egress | 依赖 Hermes scan + 政策 | **P** |
| DS-MCP1 | MCP 批准清单 / 禁临时安装 | — | **N** |
| DS-MCP2 | MCP 钉版本（禁 @latest） | — | **N** |
| DS-MCP3 | MCP 沙箱 + SCA | — | **N** |
| DS-MCP4 | 工具描述变更重审 | — | **N** |
| DS-H1 | 不可逆动作人工决策；展示精确命令 | approvals + preflight | **Y/P** |
| DS-H2 | 防审批疲劳：低风险 allow + 沙箱 | Hermes smart；Themis 未配 allowlist 策略 | **P** |
| DS-H3 | Agent 不得自批自合 | approver 分离 | **P** | 逻辑有；未测 |
| DS-A1 | 全量 tool/命令/写文件/网络日志外送 | audit 写操作 | **P** |
| DS-A2 | 异常告警（凭据文件、异常目的地、新 MCP） | incident-response | **P** |
| DS-POL | Policy-as-code / CI 拒通配与关沙箱 | verify 静态门禁 | **P** | 有 CI 味道；规则弱 |
| DS-MAT | 成熟度：Starter→Advanced | 约 **Starter～偏 Intermediate 文档**；Advanced 未达 | **P** |

---

## 3. Hermes 八层 × Themis

| Hermes 层 | Themis 是否钉死 | 覆盖 | 证据 / 缺口 |
|-----------|-----------------|------|-------------|
| 1 User authorization / messaging allowlist | 仅文档指向 | **P** | 应用 `config.example` 强制 allowlist 占位 |
| 2 Dangerous command approval | **钉** smart；禁 off；cron/unattended deny 已写入 example | **Y** | `config/config.example.yaml`；SEC-APPROVALS |
| 2b approvals.deny 硬否决 | 未写入模板 | **N** | Hermes 支持；Themis 未用 |
| 2c 禁生产 YOLO | 未写 | **N** | |
| 3 File write safety | observe 意向 | **P** | |
| 4 Container isolation | AGENTS 提醒 | **P** | 应默认 production backend |
| 5 MCP credential filtering | 未写 | **N** | |
| 6 Context / promptware scan | 禁关闭 | **Y/P** | |
| 7 Cross-session isolation | profiles | **Y/P** | |
| 8 Input sanitization (cwd allowlist) | 依赖 Hermes | **P** | |
| 容器内跳过危险命令检查 | Hermes 行为 | **EXT** | Themis 须在 privileged-plane/AGENTS **警告**：容器≠免审批业务变更 |

---

## 4. OWASP LLM Top 10 2026（Agent 相关）

| 条目 | Themis | 覆盖 | 备注 |
|------|--------|------|------|
| LLM01 Prompt Injection | Hermes scan + 禁关 | **P** | 须假定注入成功，靠权限边界 |
| LLM02 Sensitive Information Disclosure | SECURITY §2；credentials；verify 明文扫 | **Y/P** | 配置侧强；输出侧弱 |
| LLM03 Excessive Agency | 读写隔离 + 审批 + preflight | **Y/P** | 政策强；运行时强制弱 |
| LLM04 Supply Chain | 默认口令/明文门禁 | **P** | 缺 MCP/模型/skill 供应链 |
| LLM05 Data and Model Poisoning | — | **N** | |
| LLM06 Unbounded Consumption | — | **N** | |
| LLM07 Misinformation | 运维域弱相关 | **EXT** | |
| LLM08 Hidden Context Exposure | 部分（禁密钥） | **P** | |
| LLM09 Vector/Embedding | 非主场景 | **EXT** | |
| LLM10 Improper Output Handling | — | **N** | |
| Lethal trifecta | 缺 egress | **N/P** | |

**ASI（Agentic）映射（来自 LLM 文档交叉表，非独立精读 Agentic Guide）：**  
ASI01 Goal Hijack **P**；ASI02 Tool Misuse **P**；ASI03 Identity Abuse **P/Y**；ASI04 Supply Chain **N**；ASI05 Unexpected Code Exec **P**（依赖沙箱）；ASI06 Memory Poison **N**；ASI08 Cascading **N**；ASI09 Trust Exploitation **P**（审批）。

---

## 5. 404StarLink 威胁面校验（工具 → 我们该防什么）

| 星链项目 | 能力摘要（来自 detail） | 对 Themis 的含义 | 覆盖 |
|----------|------------------------|------------------|------|
| **linglong** | 资产巡航 + 端口弱口令爆破 + 管理后台识别 | 验证「弱口令/暴露管理面」仍是甲方主菜 | **Y** SEC-DEFAULT、exposure、attestation |
| **afrog** | PoC 含默认口令、未授权、信息泄露等 | 同左 + 未授权接口 | **Y/P** authz-baseline 有；缺自动化对账 |
| **fscan** | 内网综合扫描/爆破/横向 | 内网扁平 + 弱口令 | **Y/P** privileged-plane；缺内网分段专条 |
| **GShark** | GitHub/GitLab 等敏感信息泄露检测 | 密钥进库/进公开环境 | **Y** 政策；**EXT** 建议 attestation 外挂 GShark |
| **murphysec** | 依赖/供应链 CLI | skill/MCP 依赖风险 | **N/EXT** |
| **Elkeid** | 主机入侵检测 | 运行时检测 Themis 不做 | **EXT** |
| **vArmor** | 容器加固 | 容器逃逸缓解 | **EXT** |
| **CDK** | 容器/K8s 逃逸与横向 | k8s 集权面被拿后的下一步 | **P** privileged-plane 有 k8s；缺逃逸专条 |
| **CyberStrikeAI** | AI 原生安全测试平台 | 互补（攻）非替代 Themis（治） | **EXT** |
| **agentic-soc-platform** | AI+SIEM/SOAR SOC | 互补监控编排 | **EXT** |

**现场报告对齐：** SSO/弱口令/Token/Gateway→Apollo→k8s/钓鱼 — 与 linglong/afrog/fscan/CDK 威胁同族；Themis 政策面命中；运行时 IDS 需 Elkeid 类。

---

## 6. Themis 自有控制（反向：我们有的是否被外部承认）

| Themis 控制 | 外部谁要求 | 评价 |
|-------------|------------|------|
| SECURITY 六铁律 | OWASP 密钥/暴露/HITL/最小权限 | **方向正确**；加载机制须再夯实 |
| SEC-* verify | DevSecOps policy-as-code / CI | **有价值但偏浅**（存在性检查为主） |
| attestations | 合规证据 | **有**；应用外部扫描证据链 |
| safety/preflight | HITL + 运维不可逆 | **有**；补参数绑定 |
| skills/security×6 | 威胁建模与运维加固 | **有**；缺 MCP/egress/对抗测试 skill |
| 禁 approvals off | Hermes + OWASP | **强对齐** |
| 127.0.0.1 默认 | 暴露面 | **强对齐** |

---

## 7. 优先补强清单（按外部依据排序）

### P0（不做则不能声称「对照过最新 Agent 安全仍可靠」）

1. **SECURITY 进入上下文可证明**（SOUL 短注入 / auto_load / `/context` 检查）— OA/DS 均要求策略真进运行时  
2. **observe 只读落到 Hermes 真实能力** — OA-1、DS-P、LLM03  
3. **Egress allowlist + 禁生产 YOLO** — DS-S2/S3、lethal trifecta  
4. **config 模板补齐：** messaging allowlist、`approvals.deny`、生产 terminal=容器 — Hermes 八层  

### P1

5. 审批完整性（参数绑定、一次性、过期）— OA-1.4 / OA-4.4  
6. MCP 批准清单 + 钉版本 + 描述变更重审 — DS-MCP*、LLM04/ASI04  
7. 对抗测试矩阵进 CI（注入/工具滥用/审批绕过）— OA-9  
8. 输出脱敏与 tool 调用审计指标 — OA-5/6  
9. privileged-plane 增加容器逃逸/privileged pod 专条 — CDK  

### P2（EXT 推荐进文档附录）

10. GShark / murphysec 作为 attestation 外部证据  
11. Elkeid / vArmor 作为运行时叠层  
12. 多 Agent / peer 信任边界专章 — OA-7  

---

## 8. 结论（慢对照后）

1. **不是「对照太少所以结论随便」——是「对照清楚后，缺口仍然清楚」。**  
2. Themis 在 **运维身份、暴露面、弱口令、禁关审批、密钥明文** 上与现场 + 404 甲方威胁 + OWASP HITL/密钥 **对齐良好**。  
3. Themis 在 **Agent 运行时隔离、egress、MCP 供应链、输出护栏、对抗测试、多 Agent** 上相对 OWASP 2026 / DevSecOps **系统性不足**；其中多项应 **叠 Hermes + 外挂**，但 Themis 必须 **写明并门禁化「生产必须打开」**，不能停在散文。  
4. 上一版「55–65%」估分 **作废**；改用本表 **Y/P/N** 跟踪，后续每补一项改一格。

---

## 9. 建议的实施顺序（待你确认后再改代码）

1. 裁定 SECURITY 加载方案（此前 A/B/C，推荐 C）  
2. 按 §7 P0 开「对齐外部基线」变更（仍可大一统或小 PR）  
3. P1 单开 change，避免与文档对齐纠缠  

**本文件状态：** 慢对照完成；**P0 + 方案 C** 已落地（SOUL 短铁律、`disabled_toolsets`/`approvals.deny`/docker、egress+YOLO 条文与 attestation、`verify.sh` SEC-* 门禁）。P1 另开。
