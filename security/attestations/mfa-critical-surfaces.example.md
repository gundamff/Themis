# 声明：关键面已启用 MFA 或同等强认证

> 复制为 `mfa-critical-surfaces.<环境>.md`。MFA 指 TOTP/WebAuthn/企业 IdP 强策略，非仅短信。

- 环境标识: `<NAME>`
- 声明人: `<ROLE>`
- 日期: `<ISO8601>`
- 范围: SSO / API Gateway / 集权中间件 / 生产 DB 管理 / Agent Gateway
- 结果: 所列关键面均已启用 MFA 或同等强认证；共享 break-glass 账号已登记与轮换
- 证据位置: `<IdP/网关策略截图工单号或审计导出编号>`

## 关键面清单

| 表面 | 强认证已启用 |  break-glass 已登记 |
|------|--------------|---------------------|
| SSO / IdP | ☐ | ☐ |
| API Gateway | ☐ | ☐ |
| 配置/注册中心 | ☐ | ☐ |
| k8s 集群访问 | ☐ | ☐ |
| DB 管理入口 | ☐ | ☐ |
| Agent Gateway | ☐ | ☐ |

## 备注

- 对应 `SECURITY.md` 铁律 1（身份最小权限）。
- 新接入系统须在上线前补齐本声明对应行。
