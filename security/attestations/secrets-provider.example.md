# 声明：密钥由受管 Provider 注入

> 复制为 `secrets-provider.<环境>.md`。禁止在配置中心 UI、技能、日志或聊天中存放可复用明文密钥。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 范围: Hermes `config/secrets.env` 引用 / Bitwarden / 1Password / 云 KMS / CI 注入
- 结果: 生产可写凭据仅通过声明的 provider 注入；仓库与示例无真实密钥
- 证据位置: `<密钥库命名空间/保险库 ID 或 KMS 别名工单号>`

## Provider 选型（勾选其一或组合）

| Provider | 用途 | 已配置 |
|----------|------|--------|
| `env` + `.gitignore` 本地文件 | 开发/隔离环境 | ☐ |
| Bitwarden (`bw`) | 团队共享保险库 | ☐ |
| 1Password (`op`) | 团队共享保险库 | ☐ |
| 云 KMS / 平台密钥服务 | 生产注入 | ☐ |

## 轮换与审计

- 上次轮换日期: `<ISO8601>`
- 轮换责任角色: `<ROLE>`
- 扫描/泄露检测: ☐ 已启用（Hermes 密钥扫描或同等工具）

## 备注

- 与 `skills/security/credentials-hygiene` 及 `SEC-SECRETS` 门禁对齐。
- `config/secrets.env` 仅放占位符与变量名，真实值由 provider 在运行时注入。
