---
name: exposure-control
title: Exposure and Bind-Address Control
soul: SOUL.md
security: SECURITY.md
persona: observer
version: 1.0
triggers:
  - exposure review
  - bind address
  - public entry review
  - SEC-BIND
depends_on: []
required_vars: []
description: >
  Enforces SECURITY.md laws 4 and 6 with safe binding, abstract management-port inventory, and time-bounded exception evidence.
---

# Exposure and Bind-Address Control

## Bind-Address Policy

Choose the narrowest listener in this order:

1. No remote access required: bind to loopback.
2. Same-host orchestration only: use a Unix socket or equivalent local channel.
3. Internal access: bind an explicit private interface, guarded by firewall, service identity, and authorization.
4. Management planes must never bind all interfaces or face the internet directly.

A wildcard bind in configuration must trigger the `SEC-BIND` gate. A justified business listener exception needs an owner, rationale, approver, expiry, ingress controls, and removal date; privileged operations planes are not eligible.

## Abstract Management-Port Inventory

Record roles and logical ports without embedding field addresses:

| Management category | Capability | Default reachability | Required controls |
|---------------------|------------|----------------------|-------------------|
| Configuration | Publish configuration, read runtime settings | Controlled management network | Strong auth, granular authorization, audit |
| Messaging/scheduling | Manage queues, trigger jobs | Controlled management network | MFA-equivalent auth, approval, audit |
| k8s control plane/dashboard | Cluster and workload control | Dedicated control network | Least RBAC, short-lived identity, no public exposure |
| Bastion and Agent API | Session proxy, remote execution | Dedicated access network | Device control, MFA, session recording |
| Database/middleware admin | Data and cluster management | Restricted service segment | Separate admin identity, allowlist |

The operational inventory includes asset role, protocol, logical port, bound interface, ingress path, identity policy, owner, and review time.

## No Public Management Plane

- Configuration, messaging, scheduling, k8s dashboards, bastions, and Agent APIs are not internet-reachable by default.
- A CDN, reverse proxy, or hidden path is not authentication and does not make exposure private.
- An exception requires written approval, source allowlist, MFA, least privilege, complete audit, and automatic expiry.
- If source or approval cannot be proven, isolate the entry and preserve observe-only evidence.

## SEC-BIND Procedure

1. Scan configuration, container arguments, Services/Ingresses, and process listeners.
2. Reconcile listeners with inventory; identify wildcard bindings and unknown ports.
3. Test reachability from external, office, and management viewpoints instead of trusting configuration alone.
4. For management planes, verify strong auth, allowlist, audit, and exception expiry.
5. Return `pass|blocked|exception`; missing evidence means `blocked`.

```yaml
service_role: <abstract-role>
logical_port: <port-purpose>
bind_scope: loopback|private-interface|wildcard
internet_reachable: false
exception_id: <none-or-approval-reference>
status: pass|blocked|exception
```

## Regression Items

- [ ] Upgrade did not widen loopback to wildcard
- [ ] New ports are inventoried and owned
- [ ] Firewall and orchestration manifests agree
- [ ] Exceptions are current and controls reproducible
- [ ] Exposure checks and audit remain enabled
