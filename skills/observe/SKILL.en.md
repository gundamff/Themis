---
name: observe
title: System Observability Methodology
soul: SOUL.md
persona: observer
version: 1.1
triggers:
  - 观测
  - 监控
  - 巡检
  - 健康检查
  - 告警
  - 系统状态
  - observe
  - health check
  - monitoring
  - 变更感知
depends_on:
  - infra/inventory-loader
required_vars: []
description: >
  Methodology for system observability: three-layer health definition, alert levels, the difference
  between inspection and trend analysis, and monitoring blind spot identification.
  Does not include any specific monitoring tool configuration or commands — concrete implementations
  are written by users in their own local skills based on their tech stack.
---

# System Observability Methodology

> This skill is the principles and framework layer. Specific monitoring tool configurations
> (Zabbix UserParameter, Prometheus metrics, port scan scripts, etc.) are implemented by users
> in their own local skills, not defined here.

---

## Three-Layer Definition of Health

"System health" is not a single state, but a combination of three layers. Missing any layer means incomplete observability:

### Layer 1: Process Liveness (most fundamental, must be monitored)

- Whether key processes are running
- Whether listening ports are accessible
- Anomaly at this layer → service completely unavailable, must alert immediately

### Layer 2: Service Availability (functional level)

- Whether the service can handle requests normally (response time, success rate)
- Whether dependent resources are available (connection pools, storage space, downstream services)
- Anomaly at this layer → service may be partially available or degraded, needs diagnosis

### Layer 3: Business Normalcy (most important, most easily overlooked)

- Whether business data is flowing as expected (no abnormal message queue backlog, normal database write volume, inbound data volume matches historical baseline)
- Anomaly at this layer → processes may be alive, ports may be listening, but business is effectively broken

**Key insight:** Process alive ≠ service available ≠ business normal. Any layer with issues requires attention.

---

## Alert Levels

| Level | Meaning | Response Requirement | Typical Scenarios |
|-------|---------|----------------------|-------------------|
| `info` | Informational event, no action needed | Log only | Scheduled maintenance start/end |
| `warning` | Resource approaching threshold, needs attention | Handle during work hours | Disk usage >70%, memory >80% |
| `critical` | Service degradation or significant performance drop | Respond within 30 minutes | Process restart, response time 3x baseline |
| `disaster` | Service completely unavailable | Immediate response | Process not running, database unreachable |

**Principles:**
- Alerts must be "actionable": the person receiving the alert must know what to do next
- Avoid alert noise: frequently triggered alerts that don't require human intervention cause alert fatigue, causing real issues to be missed
- Every `critical` or higher alert should have a corresponding diagnostic runbook (pointing to the relevant diagnose skill)

---

## Snapshot Inspection vs Long-Term Trends

Both solve different problems and are both indispensable:

### Snapshot Inspection (high frequency, sensing immediate state)

- Purpose: discover "is there a problem right now"
- Frequency: minute-level or hour-level
- Content: current process status, number of active alerts, current values of key metrics
- Output: status report, "green/yellow/red"

### Long-Term Trend Analysis (low frequency, sensing evolutionary direction)

- Purpose: discover "problems are brewing" (capacity exhaustion, slow memory leaks, growing data backlog)
- Frequency: day-level or week-level
- Content: metric growth rates, fluctuation patterns, deviations from historical baselines
- Output: trend report, "current value / growth rate / estimated time to hit threshold"

**Common mistake:** Only doing snapshot inspections and ignoring trends, causing predictable issues like disk full or connection pool exhaustion to become emergencies.

---

## Monitoring Blind Spots

The following are the most commonly overlooked monitoring points:

### Must be monitored but frequently missing

- Whether backup tasks completed on schedule (presence of backup files within the last N hours)
- Whether scheduled tasks (crontab) executed on time
- Whether certificates/keys are approaching expiration
- Whether consumer lag is continuously growing (not just the current absolute value)
- Whether business data volume matches historical baseline (too little is also an anomaly, not just too much)

### Observed but typically useless

- Process PID (changes on every restart, limited alerting value)
- Transient spikes (a single CPU 100% event usually doesn't indicate a problem)
- Absolute values without baselines (1000 connections — is that high or low?)

### High-value alert sources

- Deviations from historical year-over-year or period-over-period comparisons (alert when deviation > N%)
- Boundary conditions: connections > 80% of max connection pool, not just > some absolute number
- Combinations of two metrics: high CPU + high disk I/O is more diagnostically valuable than either alert alone

---

## Change Awareness

Observability is not just about discovering "is there a problem right now," but also sensing "has anything changed recently" — changes are the most common root cause of failures.

### Change types that must be sensed

| Change Type | Sensing Method | Inspection Focus |
|-------------|---------------|------------------|
| Application deployment | Deployment logs, version tag changes | Correlation between deployment time and anomaly start time |
| Configuration changes | Config file hash changes, environment variable modifications | Direct relationship between changed items and anomalous metrics |
| Infrastructure changes | Scale-up/scale-down events, migration records | Traffic distribution changes, health status of new nodes |
| Dependency upgrades | Downstream service version changes | Interface compatibility, performance characteristic changes |
| Scheduled tasks | Task execution logs | Execution time coinciding with anomaly time |

### Applying change awareness in inspections

- **Snapshot inspection**: record key version numbers and configuration summaries at each inspection, compare with the previous inspection, flag changes
- **Trend analysis**: annotate trend anomaly points with recent change events, helping determine whether the issue is natural growth or change-induced

**Key principle:** Inspection reports should include a "summary of changes in the last N hours," not just the current state snapshot.

---

## Roles of Metrics, Logs, and Traces

The three are complementary and cannot replace each other:

| Signal Type | What Question It Answers | Suitable Scenarios |
|-------------|-------------------------|-------------------|
| Metrics | "Is there a problem? How severe?" | Triggering alerts, trend analysis, capacity planning |
| Logs | "What happened? Where did it fail?" | Troubleshooting, auditing, debugging |
| Traces | "Which systems did the request pass through? How long did each segment take?" | Microservice latency analysis, dependency chain tracing |

When no tracing system is available, structured logs (containing request_id/trace_id) can partially substitute for tracing functionality.

---

## The Read-Only Boundary of the Observer

The observer persona is strictly read-only:

- Can only read metrics, query logs, check ports, call read-only APIs
- Must not execute any SSH write operations
- Must not modify any monitoring configurations
- When discovering issues, output alerts/reports for the diagnoser or executor to handle

The observer is the "eyes," not the "hands."

---

## Notes for Users

This framework does not provide any specific monitoring tool configurations or scripts. Users need to:

1. Based on their own monitoring tools (Zabbix, Prometheus, Datadog, etc.), write concrete observation skills locally
2. Declare `depends_on: [observe]` in local skills to ensure methodology constraints take effect
3. Set the local skill's `persona` to `observer`
4. Write the nodes and service endpoints to be observed into `inventory/hosts.yaml`

See `skills/infra/inventory-loader` for how to read environment variables.