# 声明：容器加固叠层（vArmor 或等效）

> 复制为 `container-hardening-overlay.<环境>.md`。叠在 Hermes `terminal.backend=docker` 之外。
> 工具参考：404StarLink **vArmor**（或 seccomp/AppArmor/Pod Security 等效策略）。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 范围: Hermes sandbox 工作负载 / 编排命名空间

## 检查项

| 项 | 期望 | 实际 | 证据 |
|----|------|------|------|
| 非 privileged（与 sandbox-not-privileged 一致） | 是 | ☐ | |
| 加固策略已绑定 sandbox 工作负载 | 是 | ☐ | |
| 未挂载 docker.sock | 是 | ☐ | |
| 策略变更有审批与审计 | 是 | ☐ | |

## 备注

- 与 `privileged-plane`「Agent / 沙箱」、`SEC-SANDBOX`、附录 `docs/security/external-overlays.md` 对齐。
- vArmor 等**不能**替代业务审批票据。
