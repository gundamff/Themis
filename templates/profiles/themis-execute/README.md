# Profile: `themis-execute`

可写 Hermes profile，承载 **executor** 逻辑角色：在 `SOUL.md` / `SECURITY.md` 与预检约束下执行变更。

## 硬约束

- **必须**启用 Hermes `approvals`，且 `mode` 为 `smart` 或 `manual`，**禁止** `off`。
- **必须**在写操作前调用 `skills/safety/preflight-and-audit`。
- 所有写操作落盘审计（见 snippet 中 `audit`）。
- Profile home 须同时存在 `SOUL.md` 与 `SECURITY.md`。

## 配置键边界

- `approvals` 是 Hermes 原生审批控制，必须按安装版本的官方配置格式启用。
- snippet 中的 `persona`、`required_preflight`、`allow_skills`、`requires_approval_for`、`audit` 与 `backup_required` 表达 Themis 的策略意图；除非已由本地集成验证，不应假定它们都是 Hermes 原生配置键。
- 若要限制 executor 工具权限，应将策略映射为当前 Hermes 版本支持的 `agent.disabled_toolsets` 和/或工具 allowlist，并核对实际工具集名称。

## 安装（概要）

1. 创建 profile：`hermes profile create themis-execute`（或拷贝本目录到 `$HERMES_HOME/profiles/themis-execute`）。
2. 合并 `config.snippet.yaml`；确认 `approvals.mode: smart` 未被改为 `off`。
3. 拷贝/链接 `SOUL.md`、`SECURITY.md`；配置 `config/secrets.env`（仅变量名，值由 provider 注入）。
4. `bash scripts/verify.sh` — 期望 `SEC-PROFILE`、`SEC-APPROVALS`（在 Task 5 后）等相关项 OK。

## 切换

```bash
hermes -p themis-execute
```

## 相关技能

- `skills/safety/preflight-and-audit`（写前强制）
- `skills/security/**`（方法论门禁）
- 业务 `skills/**`（受 `requires_approval_for` 约束）
