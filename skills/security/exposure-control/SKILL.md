---
name: exposure-control
title: 暴露面与绑定地址控制
soul: SOUL.md
security: SECURITY.md
persona: observer
version: 1.0
triggers:
  - 暴露面检查
  - 端口绑定
  - 公网入口审查
  - SEC-BIND
depends_on: []
required_vars: []
description: >
  落实 SECURITY.md 第 4、6 条，以安全绑定、管理端口清单和例外证据阻断公网管理面。
---

# 暴露面与绑定地址控制

## 绑定地址策略

按以下优先级选择监听范围：

1. 不需要远程访问：绑定 loopback。
2. 仅同机编排访问：使用 Unix socket 或等价本地通道。
3. 内部访问：绑定明确私网接口，并由防火墙、服务身份和授权共同限制。
4. 管理面不得绑定全接口或直接面向互联网。

配置中的通配绑定必须触发 `SEC-BIND` 阻断。业务监听若确有例外，必须记录资产所有者、业务理由、批准人、期限、入口防护和回收日期；例外不适用于运维集权面。

## 管理端口清单抽象

清单只记录服务角色和逻辑端口，不在 skill 中固化现场地址：

| 管理面类别 | 典型能力 | 默认可达范围 | 必需控制 |
|------------|----------|--------------|----------|
| 配置中心 | 发布配置、读取运行参数 | 受控管理网 | 强认证、细粒度授权、审计 |
| 消息/调度 | 管理队列、触发任务 | 受控管理网 | MFA 或同等认证、审批、审计 |
| k8s 控制面/面板 | 工作负载与集群控制 | 专用控制网 | 最小 RBAC、短期身份、无公网 |
| 堡垒与 Agent API | 会话代理、远程执行 | 专用接入网 | 设备约束、MFA、会话记录 |
| 数据库/中间件管理端 | 数据与集群管理 | 服务网内受限段 | 独立管理身份、allowlist |

实际清单应包含：资产角色、协议、逻辑端口、绑定接口、入口路径、身份策略、所有者和复查时间。

## 禁止公网管理面

- 配置中心、消息、调度、k8s dashboard、堡垒和 Agent API 默认不得互联网可达。
- CDN、反向代理或“隐藏路径”不等于鉴权，也不改变公网暴露事实。
- 例外必须同时具备书面批准、来源 allowlist、MFA、最小授权、完整审计和自动到期。
- 无法确定来源或批准状态时，先隔离入口，保留 observe-only 证据。

## SEC-BIND 检查步骤

1. 扫描配置、容器参数、Service/Ingress 和进程监听。
2. 将监听项与资产清单逐项对齐，识别通配绑定和未知端口。
3. 从外部、办公网、管理网三个视角验证实际可达性，禁止仅凭配置下结论。
4. 对管理面检查强认证、allowlist、审计和例外到期时间。
5. 输出 `pass|blocked|exception`；缺证据一律为 `blocked`。

```yaml
service_role: <abstract-role>
logical_port: <port-purpose>
bind_scope: loopback|private-interface|wildcard
internet_reachable: false
exception_id: <none-or-approval-reference>
status: pass|blocked|exception
```

## 回归项

- [ ] 新版本未把 loopback 改为通配绑定
- [ ] 新增端口已登记且有所有者
- [ ] 防火墙与编排清单保持一致
- [ ] 例外未过期，入口控制可复验
- [ ] 暴露面检查和审计未被静默关闭
