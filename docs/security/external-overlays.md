# 外部安全叠层附录（P2 / EXT）

Themis 负责运维 Agent 的**法则、profile、规程与仓库门禁**。下列能力明确为 **外挂**：不进 Themis 内核，生产应部署并在 `security/attestations/` 留证。

来源：404StarLink 威胁面校验 + OWASP Agent 对照（见 `docs/superpowers/specs/2026-10-22-security-external-crosswalk.md`）。

---

## 1. 敏感信息与供应链证据

| 能力 | 推荐工具（示例） | Attestation 模板 | 周期建议 |
|------|------------------|------------------|----------|
| 公开仓/镜像敏感信息泄露 | GShark 或等效 | `gshark-scan.example.md` | 至少每季度 |
| 依赖与 MCP 制品 SCA | murphysec 或等效 | `murphysec-sca.example.md` | 发版前 + 季度 |

Themis 侧已有：禁明文、`SEC-DEFAULT`/`SEC-SECRETS`、MCP allowlist。外挂负责**发现**已泄露或有漏洞的制品。

---

## 2. 运行时与容器叠层

| 能力 | 推荐工具（示例） | Attestation 模板 | 说明 |
|------|------------------|------------------|------|
| 主机入侵检测 | Elkeid 或等效 EDR/HIDS | `runtime-ids-overlay.example.md` | Agent 被滥用后的主机侧可见性 |
| 容器加固 | vArmor 或 seccomp/AppArmor/PSS | `container-hardening-overlay.example.md` | 叠在 docker 沙箱外；不替代审批 |

与 P1 `sandbox-not-privileged` 同时满足：策略上禁 privileged，编排上再套加固。

---

## 3. 可选互补（未强制 attestation）

| 能力 | 示例 | 与 Themis 关系 |
|------|------|----------------|
| AI 原生安全测试（攻） | CyberStrikeAI | 互补红队；不替代 `verify-adversarial` |
| AI+SIEM/SOAR | agentic-soc-platform | 告警编排；衔接 `incident-response` |

---

## 4. 多 Agent 信任

规程见 `skills/security/multi-agent-trust/`。概要：profile/peer 之间不得隐式共享写凭据；委托默认关闭；跨 Agent 任务独立票据与审计。

---

## 5. 门禁

`scripts/verify.sh` 的 `SEC-EXT` 仅检查**模板文件存在**（不要求本机安装 GShark/Elkeid）。生产是否真正运行外挂，靠填写后的 attestation 与审计抽查。
