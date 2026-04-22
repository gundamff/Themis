# memory/index.md — Skills 索引
# Agent 在每轮会话中加载此文件，用于快速定位 skill。
# 触发词命中时自动加载对应 skill，无需手动指定。

## 如何阅读本索引

- 每行格式：`触发关键词 → skill 路径`
- Agent 对用户输入做模糊匹配，命中则加载对应 SKILL.md
- 一次请求可同时触发多个 skill（取交集，persona 权限约束优先）

---

## 安全与审计

| 触发词 | Skill |
|--------|-------|
| 高危操作、删除、重启、执行前检查、审计日志、preflight、操作审批 | `skills/safety/preflight-and-audit` |

---

## 基础设施

| 触发词 | Skill |
|--------|-------|
| 机器清单、服务器列表、主机信息、查看节点、inventory、hosts | `skills/infra/inventory-loader` |
| 凭据、密码、连接信息、credentials、secrets | `skills/infra/credentials` |

---

## 系统观测（observer）

| 触发词 | Skill |
|--------|-------|
| 观测、监控、巡检、健康检查、告警、系统状态、observe、health check、monitoring | `skills/observe` |

---

## 故障诊断（diagnoser）

| 触发词 | Skill |
|--------|-------|
| 诊断、故障、排查、根因分析、问题定位、diagnose、故障诊断、根因 | `skills/diagnose` |

---

## 数据备份（executor，需 preflight 审批）

| 触发词 | Skill |
|--------|-------|
| 备份、数据备份、备份策略、备份验证、备份恢复、backup | `skills/backup` |

---

## 集成与自动化（executor）

| 触发词 | Skill |
|--------|-------|
| webhook、事件订阅、自动触发、外部通知、告警触发 | `skills/integrate/webhook-subscriptions` |

---

## SOUL.md（三定律，始终加载，不在此索引中控制）

始终加载，优先级最高，不经过触发词机制。

---

## 本地扩展 skill

如果你在本地编写了具体系统的 skill，在此处追加触发词映射：

```
| 你的触发词 | 本地 skill 路径 |
```
