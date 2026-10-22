# Profile: `themis-approve`（可选）

审批专用 Hermes profile，承载 **approver** 逻辑角色：对 executor 预检结果做 **approve/reject**，**不**执行 shell、**不**加载可写 inventory。

也可改用 Hermes 原生 approvals 通道；本模板供需要独立审批实例时使用。

## 硬约束

- 禁止 `shell_exec`、`file_write`、`ssh` 等执行类工具。
- 仅允许读取预检/审计记录以核对 `trace_id`。
- 不得持有生产可写凭据。
- Profile home 须存在 `SOUL.md` 与 `SECURITY.md`。

## 安装（概要）

1. `hermes profile create themis-approve`（或拷贝本目录）。
2. 合并 `config.snippet.yaml`。
3. 与 `themis-execute` 的 `approvals` 配置配对测试一次完整 approve 流程。

## 切换

```bash
hermes -p themis-approve
```

## 输出契约

决策输出：`decision`（approve|reject）、`reason`（≥10 字）、`trace_id`、`signature`（sha256）。
