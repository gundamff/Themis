# Profile: `themis-observe`

只读 Hermes profile，承载 **observer** 与 **diagnoser** 逻辑角色：巡检、诊断、根因分析，**不得**变更生产状态。

## 硬约束

- 无写工具（见 `config.snippet.yaml` 中 `deny_tools`）。
- 不加载可写生产凭据；inventory 使用只读视图或脱敏副本。
- `approvals` 块可省略；若配置则 **禁止** `mode: off`。
- Profile home 须同时存在 `SOUL.md` 与 `SECURITY.md`（与 Hermes 不可变法则一致）。

## 配置键边界

- Hermes 原生安全控制包括 `approvals`，以及安装版本实际支持的 `agent.disabled_toolsets` / 工具 allowlist。
- snippet 中的 `persona`、`allow_skills`、`deny_tools`、`allow_shell_patterns` 与 `audit` 表达 Themis 的策略意图；除非已由本地集成验证，不应假定它们都是 Hermes 原生配置键。
- `deny_tools` 尤其需要映射为当前 Hermes 版本的 `agent.disabled_toolsets` 和/或工具 allowlist；请按官方文档核对实际工具集名称，不要原样复制后假定隔离已生效。

## 安装（概要）

1. 创建 profile：`hermes profile create themis-observe`（或从本目录拷贝到 `$HERMES_HOME/profiles/themis-observe`）。
2. 将 `config.snippet.yaml` 合并进该 profile 的 `config.yaml`。
3. 拷贝/链接仓库根目录的 `SOUL.md`、`SECURITY.md` 到 profile home。
4. 运行 `bash scripts/verify.sh`，确认 `SEC-PROFILE` 与相关 `SEC-*` 通过。

## 切换

```bash
hermes -p themis-observe
```

## 相关技能

- `skills/observe/**`
- `skills/diagnose/**`
- `skills/security/threat-model`（只读分析）
