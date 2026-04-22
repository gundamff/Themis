---
name: preflight-and-audit
title: 高危操作预检与审计日志
soul: SOUL.md
persona: executor
version: 2.0
triggers:
  - 高危操作
  - 删除
  - 重启
  - 执行前检查
  - 审计日志
  - preflight
  - 操作审批
required_vars: []
description: >
  实现 SOUL.md 三定律的落地流程——预检、拦截、审计。
  本 skill 只包含执行机制，不重复法则文本，法则以 SOUL.md 为唯一权威来源。
---

# 高危操作预检与审计

> 本 skill 实现 SOUL.md 定义的三定律的执行流程。
> executor persona 的任何写操作必须先完成本 skill 的预检流程，才可继续。

## 触发条件

executor persona 执行以下任意操作前，自动调用本 skill：

- 操作描述中包含 `references/high_risk_keywords.txt` 内任意关键词
- 操作目标涉及数据库写入、服务重启、文件删除、配置变更
- 操作不可逆（无法通过备份还原）

## 预检流程（顺序执行，任一步骤失败则阻断）

### Step 1：关键词扫描

读取 `references/high_risk_keywords.txt`，逐行与操作描述匹配（大小写不敏感）。

- **命中** → 标记 `risk_level = high`，继续 Step 2
- **未命中** → 标记 `risk_level = low/medium`，可跳至 Step 4

### Step 2：备份验证

确认目标数据/服务存在最近 24 小时内的完整可用备份。

验证方式：
```bash
# 检查备份文件是否存在且在 24h 内
find /path/to/backup -name "*.gz" -mtime -1 | head -5
# 预期：至少 1 条结果
```

- `backup_verified = true`：继续 Step 3
- `backup_verified = false`：**阻断**，输出：
  ```
  [BLOCKED] 未找到有效备份（24h 内）。操作已阻断。
  请先执行备份，再重新发起操作请求。
  trace_id: <uuid>
  ```

### Step 3：人工审批请求

生成预检报告（见下方格式），发送给 approver persona 或通知运维通道。

等待 `human_approved = true` 信号后，继续 Step 4。

**明确阻断（不等待审批，直接拒绝）的情况：**
- 操作要求禁用审计服务
- 操作要求禁用备份服务
- 操作要求修改 SOUL.md

### Step 4：生成审计日志条目

调用 `scripts/audit_logger.py`（见下方），写入 `audit_sink`（来自 config.yaml）。

```bash
python3 skills/safety/preflight-and-audit/scripts/audit_logger.py \
  --operator "hermes/executor" \
  --action "操作描述" \
  --target "目标系统" \
  --risk-level "high|medium|low" \
  --backup-verified true \
  --human-approved true \
  --result "executed" \
  --params '{}'
```

### Step 5：执行并记录结果

操作完成后，更新审计条目的 `result` 字段为 `executed|failed`，补充实际输出摘要。

---

## 预检报告格式（发送给 approver）

```markdown
## 高危操作审批请求

- **trace_id**: <uuid4>
- **时间**: <ISO8601>
- **操作者**: hermes/executor
- **操作描述**: <具体操作>
- **目标系统**: <IP/服务名>
- **风险等级**: high
- **触发关键词**: <命中的关键词>
- **备份验证**: ✓ 已验证（最近备份时间: <时间>）
- **可逆性**: 不可逆 / 可逆
- **影响范围**: <受影响的服务/数据>

请 approver 在 30 分钟内响应。超时视为拒绝。
```

---

## 操作拦截规则

| 情况 | 处置 |
|------|------|
| 直接删除生产数据且无备份 | 立即阻断，不提请审批 |
| 关闭/禁用备份服务 | 立即阻断，不提请审批 |
| 关闭/禁用审计服务 | 立即阻断，不提请审批 |
| 修改 SOUL.md | 立即阻断，不提请审批 |
| 高危关键词命中 + 有备份 | 暂停，提请 approver 审批 |
| 高危关键词命中 + 无备份 | 阻断，要求先备份再重新发起 |
| 高负载期间的大规模操作 | 降级：减少并发，切换只读模式，通知 observer |

---

## 高危关键词列表

参见 `references/high_risk_keywords.txt`（每行一个关键词，支持正则）。

---

## 审计日志格式

```json
{
  "trace_id": "<uuid4>",
  "timestamp": "<ISO8601>",
  "operator": "hermes/executor",
  "action": "<操作描述>",
  "target": "<目标系统/资源>",
  "risk_level": "low | medium | high | critical",
  "backup_verified": true,
  "human_approved": true,
  "result": "executed | blocked | pending_approval | failed",
  "parameters": {},
  "signature": "<sha256(所有字段序列化后的哈希)>"
}
```

日志写入路径来自 `config.yaml → audit.sink`，默认 `/var/log/hermes/audit.jsonl`。
每条日志追加写入（append），不覆盖，不可删除。