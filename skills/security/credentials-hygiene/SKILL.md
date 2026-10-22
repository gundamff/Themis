---
name: credentials-hygiene
title: 凭据卫生与轮换
soul: SOUL.md
security: SECURITY.md
persona: executor
version: 1.0
triggers:
  - 凭据配置
  - 密钥轮换
  - secrets provider
  - 上线验收
depends_on: []
required_vars: []
description: >
  落实 SECURITY.md 第 1、2、5、6 条，禁止默认或明文凭据并规范 provider、轮换和证明材料。
---

# 凭据卫生与轮换

> 技能文件、日志、聊天和审计样例中禁止写入任何真实或可复用凭据；仅记录引用、指纹和状态。

## 不可妥协规则

- 禁止默认口令、共享口令和长期人工账号；首次启用前必须替换安装初值。
- 禁止空值回退、硬编码、命令行参数传密和日志打印。
- 只读 profile 不得取得写入生产的凭据；executor 的写入身份必须独立且经过审批。
- 不得关闭密钥扫描、审计或轮换告警；这对应 SECURITY.md 第 6 条。

## Provider 策略：env / bw / 1p

| Provider | 允许场景 | 约束 |
|----------|----------|------|
| `env` | CI 或容器运行时的短期注入 | 值由外部密钥系统注入；配置仅保存变量名；进程结束即失效 |
| `bw` | 受管 Bitwarden 机密引用 | 使用条目/字段引用和受限机器身份；不得把解析值写回磁盘 |
| `1p` | 受管 1Password 机密引用 | 使用 vault/item/field 引用和短期服务身份；最小化 vault 范围 |

provider 不可用时必须失败关闭，禁止回退到仓库文件、示例值或交互式共享口令。

## 轮换流程

1. 盘点主体、用途、权限、provider 引用、所有者和到期时间，不采集明文值。
2. 在 provider 中创建新版本，限制作用域并设置有效期。
3. 灰度切换消费者，验证认证和最小权限，不在输出中回显值。
4. 吊销旧版本，确认缓存、会话和离线副本失效。
5. 记录时间、操作者、引用标识、指纹后缀和验证结果。
6. 紧急泄露直接走 incident-response，不等待常规轮换窗口。

建议周期由资产等级决定：A0/A1 使用短期或自动轮换；A2 定期轮换；A3 若无凭据则不得新增。

## Attestation 对应

填写 `security/attestations/secrets-provider.example.md` 时至少证明：

| 证明项 | 记录内容（不得含秘密值） |
|--------|--------------------------|
| provider | `env`、`bw` 或 `1p` |
| secret reference | 变量名或 provider 路径引用 |
| scope | 可访问的系统、环境和动作 |
| rotation | 最近/下次轮换时间与负责人 |
| validation | 运行时注入、旧版本吊销、扫描通过的证据 |
| separation | observer 与 executor 使用不同身份的证据 |

模板缺失或证明不完整时，验收状态必须为 `blocked`，不得自造空证明。

## 检查清单

- [ ] 安装初值已替换，不存在默认或共享凭据
- [ ] 仓库、配置、日志、聊天和技能文件无秘密值
- [ ] provider 引用可解析，失败时关闭
- [ ] 权限与用途相符，读写身份隔离
- [ ] 轮换、吊销和回滚均已演练
- [ ] attestation 有负责人、时间和可复验证据

## 安全输出示例

```yaml
provider: bw
reference: <collection/item/field>
principal: <service-role>
scope: <read-only-or-approved-write>
last_rotated: <ISO8601>
status: verified|blocked
```
