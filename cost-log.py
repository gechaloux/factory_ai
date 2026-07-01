#!/usr/bin/env python3
"""
cost-log.py — observability hook (PostToolUse, matcher "*").

Appends a per-turn record to ~/.claude/factory-log.jsonl: which line, which tool, and any
cost/latency/token fields Claude Code provides in the hook payload. This is the factory's
observability layer — the thing that lets you see whether a line is iterating efficiently or
quietly burning tokens. Cheap, append-only, never blocks the loop.
"""

import sys, os, json, time

def line_name(cwd):
    # Walk up to the line root (.factory marker). Terminate on dirname(d) == d so this
    # works on Windows ('C:\\') as well as POSIX ('/'); a 'd != "/"' guard never trips on
    # Windows and loops forever.
    d = os.path.abspath(cwd)
    while True:
        fp = os.path.join(d, ".factory")
        if os.path.exists(fp):
            for ln in open(fp):
                if ln.strip().startswith("name:"):
                    return ln.split(":", 1)[1].strip()
            return os.path.basename(d)
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    cwd = payload.get("cwd") or os.getcwd()
    rec = {
        "ts": time.time(),
        "kind": "turn",
        "line": line_name(cwd),
        "tool": payload.get("tool_name"),
        # Pass through whatever cost/usage telemetry is present; absence is fine.
        "usage": payload.get("usage") or payload.get("cost") or {},
        "model": payload.get("model"),
    }
    log = os.path.expanduser("~/.claude/factory-log.jsonl")
    os.makedirs(os.path.dirname(log), exist_ok=True)
    try:
        with open(log, "a") as f:
            f.write(json.dumps(rec, default=str) + "\n")
    except Exception:
        pass
    sys.exit(0)

if __name__ == "__main__":
    main()
