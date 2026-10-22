# Final whole-branch review 修复报告

**分支:** `feat/hermes-security-hardening`
**范围:** Important / Minor；保持 `SECURITY.md` 独立文件架构

## 修复

- Webhook 示例默认绑定 `127.0.0.1`，公网绑定明确要求书面例外、来源 allowlist 与 MFA。
- SSH 示例默认启用严格主机密钥校验。
- 中英文 `SOUL.md` 均声明与 `SECURITY.md` 冲突时双重拒绝。
- 安装脚本在设置 `HERMES_HOME` 时复制 `SECURITY.md`，并打印 profile 创建或复制路径。
- 三个 profile README 区分 Themis 策略意图与 Hermes 原生控制，说明 `deny_tools` 的实际映射要求。
- 中英文 `AGENTS.md` 说明 Hermes 加载现实及 profile 不等同于 OS 沙箱。

未合并 `SECURITY.md` 正文到 `SOUL.md`，未削弱 `scripts/verify.sh` 门禁。

## 验证

```text
bash -n scripts/install.sh
bash scripts/verify.sh
FAIL: 0
WARN: 0
全部检查通过。
EXIT: 0
```

`git diff --check`：EXIT 0。
