---
name: privileged-plane
title: 运维集权面加固
soul: SOUL.md
security: SECURITY.md
persona: executor
version: 1.0
triggers:
  - 集权面加固
  - 配置中心审查
  - k8s 控制面
  - 堡垒机检查
depends_on: []
required_vars: []
description: >
  以“一拿全网”为失陷假设，加固配置、消息、调度、k8s 与堡垒等运维集权面。
---

# 运维集权面加固

## 核心假设：一拿全网

配置中心、消息平台、调度系统、k8s 控制面和堡垒不是普通后台。评估时假设任一面被攻破后，攻击者会立即寻找全域凭据、批量执行能力和横向入口。

设计目标不是“入口不容易被猜到”，而是单点失陷后仍无法跨越身份、网络、授权、审批和审计边界。

## 通用加固基线

- **身份**：禁默认/共享身份；MFA 或同等强认证；服务身份短期化。
- **密钥**：仅 provider 引用和运行时注入；禁止在 UI、配置、日志中出现可复用值。
- **网络**：管理面零公网，专用管理网与来源 allowlist，出站同样最小化。
- **授权**：默认拒绝；observer 只读，executor 写入限时限域并绑定审批。
- **审计**：登录、授权变更、密钥操作和执行动作全记录，且不可静默关闭。
- **韧性**：备份配置与审计证据；演练隔离、吊销和只读降级。

## 分平台加固清单

### 配置中心

- [ ] 命名空间与环境隔离，生产发布需要审批
- [ ] 配置仅含密钥引用，不含可复用秘密
- [ ] 读取与发布权限分离，变更可追溯和回滚
- [ ] 客户端身份仅可访问所需命名空间

### 消息平台

- [ ] 管理 API 与数据平面分离，均拒绝匿名
- [ ] topic/queue 按服务授权，禁止通配管理权限
- [ ] 高影响消息具备签名、幂等和速率限制
- [ ] 管理动作与消费异常纳入审计

### 调度系统

- [ ] 创建、修改、立即执行和补数分别授权
- [ ] 任务运行身份不继承调度平台管理员权限
- [ ] 命令与参数使用 allowlist，敏感输出脱敏
- [ ] 批量执行有审批、并发限制和熔断

### k8s 控制面

- [ ] API 与 dashboard 无公网，禁匿名和通配 RBAC
- [ ] 工作负载身份按 namespace/service account 最小化
- [ ] 高权限角色绑定限时、审批并持续审计
- [ ] admission、审计和密钥扫描不得关闭

### 堡垒

- [ ] 强认证、设备约束、个人账号和会话录制
- [ ] 目标资产按角色分组，不提供全网默认可达
- [ ] 文件传输、端口转发和提权单独审批
- [ ] 退出后吊销临时凭据并关闭残留会话

### Agent / 沙箱工作负载（容器逃逸面 · CDK 同族）

Hermes `terminal.backend: docker` 把命令放进容器，**不等于**安全边界已成立。错误挂载会把隔离挖空。

生产 Agent 沙箱必须满足：

- [ ] **禁止** `privileged: true`（无书面时限例外）
- [ ] **禁止** 挂载宿主机 `docker.sock`（或等价容器引擎 socket）
- [ ] **禁止** 默认 `hostNetwork` / `hostPID` / 挂载宿主机根 `/`
- [ ] 能力集裁剪；偏好只读根文件系统与非 root
- [ ] 业务变更仍须审批票据（容器内危险命令提示被跳过 ≠ 已批准）
- [ ] 填写 `security/attestations/sandbox-not-privileged.<环境>.md`

任一项不满足 → 按集权面失陷的下一步（逃逸/横向）评估为 `critical`。

## 验证“一拿全网”是否被阻断

1. 选择一个抽象集权面，假设其应用层身份已失陷。
2. 枚举能读取的密钥引用、能到达的网络和能执行的动作。
3. 验证不能跨环境、跨租户或提升为基础设施管理员。
4. 验证高影响动作仍需独立身份与人工审批。
5. 验证异常会被审计发现，并可进入 observe-only 熔断。

任一步能直接取得全域控制即为 `critical`，不得用“仅内网”降级风险。

## 输出

```yaml
plane: configuration|messaging|scheduler|k8s|bastion
compromise_assumption: application-identity-lost
reachable_scope: <abstract-scope>
domain_wide_control_blocked: true|false
evidence: [<control evidence>]
status: pass|blocked
```
