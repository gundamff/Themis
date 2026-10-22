# 声明：Agent 沙箱非 privileged / 无逃逸捷径

> 复制为 `sandbox-not-privileged.<环境>.md`。对齐 CDK 类容器逃逸威胁面。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 范围: Hermes `terminal.backend` 所用镜像与编排参数

## 检查项

| 项 | 期望 | 实际 | 证据 |
|----|------|------|------|
| `privileged` | false | ☐ | |
| 挂载 `docker.sock` | 无 | ☐ | |
| `hostNetwork` / `hostPID` | 默认无 | ☐ | |
| 挂载宿主机根 `/` | 无 | ☐ | |
| 运行用户 | 非 root 或已裁剪 capability | ☐ | |

## 备注

- 与 `skills/security/privileged-plane`「Agent / 沙箱工作负载」及 `SEC-SANDBOX` 对齐。
- 临时例外须时限、审批与回滚；容器内跳过危险命令提示 **不** 免除业务审批票据。
