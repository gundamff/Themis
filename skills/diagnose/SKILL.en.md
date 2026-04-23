---
name: diagnose
title: Fault Diagnosis Methodology
soul: SOUL.md
persona: diagnoser
version: 1.1
triggers:
  - 诊断
  - 故障
  - 排查
  - 根因分析
  - 问题定位
  - diagnose
  - 故障诊断
  - 根因
  - 影响评估
  - 现场保留
  - 变更关联
  - 时间线回溯
  - 证据甄别
  - 复盘
  - incident response
  - 止损
depends_on:
  - infra/inventory-loader
required_vars: []
description: >
  The mental framework, layered troubleshooting order, root cause determination criteria,
  and diagnostic report specification for fault diagnosis.
  Does not contain any system-specific check commands—concrete implementations are written
  by users in local skills based on their own tech stack.
---

# Fault Diagnosis Methodology

> This skill is the principles and process layer. Concrete check commands (process status,
> log queries, metric reads, etc.) are implemented by users in their own local skills,
> not defined here.

---

## Incident Response Lifecycle

Fault diagnosis is not an isolated step, but one link in a full lifecycle. The diagnoser must understand the complete process to do the right thing at the right time:

```
Impact Assessment → Recover Service → Preserve Evidence → Investigate Root Cause → Verify Fix → Post-Incident Review
  ↑                                                                          ↓
  └────────────── Next incident restarts from the left ──────────────────────┘
```

1. **Impact Assessment** (executed first): Confirm the business scope affected, number of users impacted, and risk of data loss. Output: impact level (high/medium/low)
2. **Recover Service** (recovery first): While preserving evidence, prioritize restoring service availability (rate limiting, graceful degradation, failover to standby, etc.). This step is executed by the executor; the diagnoser provides recommendations
3. **Preserve Evidence** (mandatory before investigation): Collect logs, metric snapshots, core dumps, and other evidence to prevent recovery operations from erasing critical information
4. **Investigate Root Cause** (core of this skill): Use the Observe → Hypothesize → Verify loop to pinpoint the root cause
5. **Verify Fix**: Confirm the fix is effective and has not introduced new issues
6. **Post-Incident Review**: Produce a review report, distilled into preventive measures and monitoring improvements

**Key principle: Recovery takes priority over investigation.** The ultimate goal of diagnosis is to restore the business, not merely to find the root cause.

---

## Diagnostic Loop: Observe → Hypothesize → Verify

### Mental Framework: What → Why → How

Before starting the investigation, use three questions to clarify direction:

- **What**: What is the symptom? How large is the impact scope? When did it start?
- **Why**: Why did it happen? List 1-3 most likely root cause hypotheses
- **How**: How to verify? Design the lowest-cost check steps for each hypothesis

All fault diagnosis must follow this loop. No skipping steps:

```
Observe: Collect symptoms (when, which service, how large the impact scope)
  ↓
Hypothesize: Based on symptoms, propose 1-3 most likely root cause hypotheses
  ↓
Verify: For each hypothesis, execute the lowest-cost check to confirm or rule out
  ↓
  ├─ Hypothesis confirmed → Record root cause, output fix recommendations
  └─ Hypothesis ruled out → Revise hypothesis, continue the loop
```

**Prohibited practices:**
- Executing fix operations based on gut feeling (violates the Second Law)
- Verifying multiple hypotheses simultaneously without recording each result
- Assuming "it looks like problem X" means it is problem X—evidence is required
- Executing any operation that might erase evidence before preserving the scene

---

## Layered Troubleshooting Order

Start from the outermost layer and work inward. Only move to the next layer after ruling out the current one:

```
Layer 1: User / Business Layer
  └─ Symptoms: Which users/businesses are affected? Is it reads or writes? Fully unavailable or intermittent?

Layer 2: Application Service Layer
  └─ Checks: Is the process alive? Is the port listening? Any ERROR/EXCEPTION in application logs?

Layer 3: Middleware Layer
  └─ Checks: Database connection count, cache hit rate, message queue backlog, service registration status

Layer 4: Infrastructure Layer
  └─ Checks: CPU/memory/disk/network metrics, system logs (OOM/disk full/network packet loss)

Layer 5: Hardware / Network Layer
  └─ Checks: Node connectivity, physical network, storage I/O performance
```

**Principle:** Don't skip the application layer just because "my gut says it's a database problem." The point of layered troubleshooting is to avoid misdiagnosis and missed correlated root causes.

---

## Root Cause Determination Criteria

A factor can only be identified as the root cause when all of the following conditions are met:

1. **Sufficiency**: This factor occurring → necessarily causes the observed symptom
2. **Necessity**: Eliminating this factor → the symptom disappears (or can be expected to disappear)
3. **Temporal order**: The anomaly in this factor occurred at or before the symptom first appeared
4. **Evidence chain**: Supported by reproducible logs, metrics, or command output, not inference

When only some conditions are met, mark as "suspected root cause" and continue collecting evidence.

---

## Evidence Preservation

Before investigating, you must preserve the scene. Any recovery operation may erase critical evidence.

### Evidence Types That Must Be Preserved

| Evidence Type | Preservation Method | Why It Matters |
|---------------|---------------------|----------------|
| Process state | Process stack snapshot (do not modify the process) | Crash root cause is often in the stack trace |
| System metrics | Capture a metric snapshot for the incident window | Metrics return to normal after recovery; raw data is not reproducible |
| Error logs | Copy incident-window logs to a separate directory | Log rotation may overwrite original records |
| Network state | Snapshot of current connections, packet loss rate, DNS cache | Network state is transient and fleeting |
| Config snapshot | Complete save of currently effective configuration | Confirm whether any unexpected config changes occurred |

### Evidence Preservation Principles

1. **Read-only principle**: All evidence preservation operations must be read-only, modifying no system state
2. **Priority principle**: Preserve the most volatile evidence first (in-memory data, transient network state, process stacks)
3. **Completeness principle**: Better to preserve too much than to miss critical evidence—retroactive collection is often impossible
4. **Isolation principle**: Store preserved evidence in a separate directory, isolated from analysis workspaces, to prevent accidental modification of original evidence

---

## Change Correlation and Timeline Backtracking

One of the most common root causes of production incidents is **recent changes**. Diagnosis must proactively correlate change events.

### Timeline Backtracking Method

1. **Mark the time the symptom first appeared** (T0)
2. **Look-back window**: Review change records before T0 (default look-back: 24h for application changes, 7d for infrastructure changes)
3. **Check each change individually**: Assess causality between each change and the symptom
4. **Correlation determination**: Change time, change scope, and incident scope are necessary correlation conditions

### Change Types and Backtracking Focus

| Change Type | Look-back Window | Common Causal Patterns |
|-------------|------------------|------------------------|
| Application release | 24h | Symptom disappears after version rollback |
| Configuration change | 24h | Config item directly correlates with the incident metric |
| Infrastructure change | 7d | Scale-up/scale-down/migration causes traffic distribution shift |
| Dependency upgrade | 7d | Downstream dependency version incompatibility |
| Scheduled task | Same day | Scheduled task timing coincides with the incident |

### Change Correlation Judgment Criteria

Do not determine causality based on temporal proximity alone. All of the following conditions must be met to establish correlation:

- **Temporal order**: The change occurred at or before the symptom first appeared
- **Scope overlap**: The change's impact scope intersects with the incident's impact scope
- **Reproducibility**: The symptom disappears after reverting the change, or reapplying the change reproduces the symptom

When the reproducibility condition is not met, mark as "suspected correlated change" and continue collecting evidence.

---

## Correlated Diagnosis Principles

A single symptom often has multiple associated components that need to be checked simultaneously:

- **Data not writing** → Check: application-layer errors, message queue backlog, database connectivity
- **Service response slowdown** → Check: database slow queries, cache invalidation/hit rate drop, upstream/downstream dependency latency
- **Node load anomaly** → Check: unexpected batch jobs, abnormal log file growth, memory leak signs
- **Intermittent failures** → Check first: network layer (packet loss/timeout), resource thresholds (connection pool exhaustion/disk intermittently full)

**Correlated diagnosis is not "check everything at once."** It means expanding the check scope in a targeted way based on symptom patterns.

---

## Evidence Triage Principles

Not every observed anomaly is a signal pointing to the root cause. Diagnosis must triage evidence quality.

### Evidence Classification

| Level | Definition | Diagnostic Weight |
|-------|------------|-------------------|
| **Conclusive evidence** | Logs/metrics/output that directly prove the root cause, reproducible | Required condition for root cause determination |
| **Supporting evidence** | Related to the root cause but cannot independently prove it, e.g., anomalous changes in indirect metrics | Supports the hypothesis but insufficient to lock down the root cause |
| **Noise** | Anomalies unrelated to the root cause, e.g., historical stale alerts, independent failures in other services | Must be ruled out, otherwise misleads the investigation |

### Triage Methods

1. **Temporal consistency**: Does the anomaly's appearance time match the incident time? Appearing earlier → may be an early warning signal; appearing later → may be a consequence rather than a cause
2. **Scope consistency**: Does the anomaly's impact scope match the incident's impact scope? Mismatch → likely noise
3. **Causal direction**: Does A cause B, or does B cause A? Or does C cause both A and B simultaneously? Counterexample: high CPU → slow process, or slow process → request pileup → high CPU?
4. **Elimination method**: After ruling out all noise, is the remaining evidence sufficient to support the root cause conclusion?

**Principle: Better to withhold the conclusion than to treat noise as root cause evidence.**

---

## Diagnoser's Read-Only Boundary and Recovery Recommendation Duty

The diagnoser persona is strictly read-only. The following operations are absolutely prohibited during the diagnosis phase:

| Prohibited Operation | Reason |
|----------------------|--------|
| Restarting a service | Erases scene evidence and may mask the root cause |
| Modifying configuration | Cannot predict the impact of changes during diagnosis |
| Deleting logs/temp files | This is evidence and must not be destroyed |
| Executing any write SQL | May alter data, making restoration impossible |
| Killing a process | Equivalent to restarting; same reasons apply |

**Recovery First principle**: The read-only boundary does not mean "don't do recovery." The diagnoser must prioritize providing recovery recommendations (rate limiting, graceful degradation, failover to standby, etc.) in the diagnostic report, to be executed by the executor persona. Restoring service takes priority over pinpointing the root cause.

All fix operations must be output as "recommendations" for the executor persona or a human to carry out.

---

## Diagnostic Report Format

At the end of every diagnosis, a report in the following format must be produced. No sections may be omitted:

```markdown
## Fault Diagnosis Report

**Diagnosis Time**: <ISO8601>
**Operator**: hermes/diagnoser
**Trigger**: <Alert description or user request>

### Impact Assessment
- **Impact Level**: High / Medium / Low
- **Impact Scope**: <Affected businesses, user groups, data volume>
- **Data Loss Risk**: <Whether there is risk of data loss or inconsistency>

### Recovery Recommendations (Execute First)
1. <Immediately actionable recovery measures: rate limiting/degradation/failover to standby, etc.>
2. <Post-recovery observation points>

### Symptom Description
- <Specific description of observed anomalies, including time first detected, impact scope, severity>

### Investigation Process
| Step | Check Item | Result | Conclusion |
|------|-----------|--------|------------|
| 1    | ...       | ...    | Ruled out / Confirmed |

### Change Correlation
- **Recent Changes**: <List of relevant changes before T0; if none, note "No correlated changes">
- **Correlation Determination**: <Whether a change is confirmed as causally related to the incident, and the basis for judgment>

### Evidence Triage
- **Conclusive Evidence**: <Key logs/metrics that directly prove the root cause>
- **Supporting Evidence**: <Indirectly related anomalous signals>
- **Ruled-out Noise**: <Anomalies observed but unrelated to the root cause>

### Root Cause Conclusion
- **Root Cause**: <One-sentence description>
- **Evidence Chain**: <Complete causal chain from symptom to root cause>
- **Confidence**: High / Medium / Low (with explanation)

### Fix Recommendations
1. <Specific, actionable fix steps for the executor or a human to carry out>
2. ...

### Post-Incident Review and Prevention
- **Root Cause Category**: <Code defect / Configuration error / Insufficient capacity / Dependency failure / Unknown>
- **Exposed Monitoring Gaps**: <Which anomalies could not be detected in advance; what new monitoring is needed>
- **Process Improvements**: <Shortcomings in the response process and improvement directions>
- **Preventive Measures**: <How to prevent similar incidents from recurring>
```

---

## User Notes

This framework does not provide any system-specific check commands. Users need to:

1. Based on their own tech stack (database type, message queue, caching solution, etc.), write concrete diagnostic skills locally
2. Declare `depends_on: [diagnose]` in local skills to ensure methodology constraints take effect
3. Set the local skill's `persona` to `diagnoser`; do not downgrade to `executor`
4. Write the node information needed for checks into `inventory/hosts.yaml`

See `skills/infra/inventory-loader` for how to read environment variables.
