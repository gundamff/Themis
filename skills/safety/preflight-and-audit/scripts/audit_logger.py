#!/usr/bin/env python3
"""
审计日志生成器 — 三定律合规
executor persona 的每次写操作必须调用本脚本生成不可篡改的审计条目。
"""

import json
import uuid
import hashlib
import argparse
from datetime import datetime, timezone


def create_audit_entry(operator, action, target, risk_level,
                       backup_verified, human_approved, result, parameters):
    trace_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    entry = {
        "trace_id": trace_id,
        "timestamp": timestamp,
        "operator": operator,
        "action": action,
        "target": target,
        "risk_level": risk_level,
        "backup_verified": backup_verified,
        "human_approved": human_approved,
        "result": result,
        "parameters": parameters,
    }

    canonical = json.dumps(entry, sort_keys=True, ensure_ascii=False)
    entry["signature"] = hashlib.sha256(canonical.encode()).hexdigest()
    return entry


def log_audit_entry(entry, log_file):
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Hermes Audit Logger")
    parser.add_argument("--operator", default="hermes/executor")
    parser.add_argument("--action", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--risk-level", default="medium",
                        choices=["low", "medium", "high", "critical"])
    parser.add_argument("--backup-verified", type=lambda x: x.lower() == "true",
                        default=False)
    parser.add_argument("--human-approved", type=lambda x: x.lower() == "true",
                        default=False)
    parser.add_argument("--result", default="pending_approval",
                        choices=["executed", "blocked", "pending_approval", "failed"])
    parser.add_argument("--params", default="{}")
    parser.add_argument("--log-file", default="/var/log/hermes/audit.jsonl")

    args = parser.parse_args()

    try:
        parameters = json.loads(args.params)
    except json.JSONDecodeError:
        parameters = {"raw": args.params}

    entry = create_audit_entry(
        operator=args.operator,
        action=args.action,
        target=args.target,
        risk_level=args.risk_level,
        backup_verified=args.backup_verified,
        human_approved=args.human_approved,
        result=args.result,
        parameters=parameters,
    )

    print(json.dumps(entry, indent=2, ensure_ascii=False))

    try:
        log_audit_entry(entry, args.log_file)
    except OSError as e:
        print(f"[WARN] 审计日志写入失败: {e}，请检查 {args.log_file} 的写入权限。")


if __name__ == "__main__":
    main()