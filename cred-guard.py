#!/usr/bin/env python3
"""
cred-guard.py — secret-leak guard (PreToolUse, matcher Edit|Write|Bash).

Enforces the factory's one universal hard rule: never hardcode secrets. Scans the content about
to be written or the command about to run for things that look like literal credentials. On a hit,
exits non-zero with a message — Claude Code treats a non-zero PreToolUse hook as a block, so the
write/commit does not happen. Generic by design: not tied to any specific broker or vault. It only
says "this looks like a hardcoded secret"; where creds SHOULD come from is a per-line decision.

Heuristic, not exhaustive. Tuned to catch the obvious leaks (keys, tokens, connection strings with
inline passwords) without drowning prototyping in false positives.
"""

import sys, os, json, re

PATTERNS = [
    (r"AKIA[0-9A-Z]{16}", "AWS access key id"),
    (r"aws_secret_access_key\s*=\s*['\"][^'\"]{30,}['\"]", "AWS secret key literal"),
    (r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "private key"),
    (r"(?i)(api[_-]?key|secret|token|passwd|password)\s*[:=]\s*['\"][^'\"]{8,}['\"]", "inline secret literal"),
    (r"(?i)://[^:/\s]+:[^@/\s]{6,}@", "credentials in a connection URL"),
    (r"ghp_[A-Za-z0-9]{30,}", "GitHub token"),
    (r"sk-[A-Za-z0-9]{20,}", "API secret key (sk- form)"),
]

# Allow obvious placeholders so prototyping isn't blocked by example values.
PLACEHOLDER = re.compile(r"(?i)(your[_-]?|example|placeholder|xxxx|<.*?>|dummy|changeme|redacted)")

def content_under_inspection(payload):
    # Claude Code passes tool arguments under "tool_input" (older/other harnesses used
    # tool_args/args — kept as fallbacks). Field names vary by tool (command, content,
    # new_string, file_text, ...), so scan every string value rather than a fixed key list.
    args = payload.get("tool_input") or payload.get("tool_args") or payload.get("args") or {}
    parts = []

    def walk(v):
        if isinstance(v, str):
            parts.append(v)
        elif isinstance(v, dict):
            for x in v.values():
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)

    walk(args)
    return "\n".join(parts)

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # don't block on a malformed payload

    text = content_under_inspection(payload)
    if not text:
        sys.exit(0)

    for pat, label in PATTERNS:
        for m in re.finditer(pat, text):
            window = text[max(0, m.start() - 20): m.end() + 20]
            if PLACEHOLDER.search(window):
                continue  # looks like a placeholder, allow
            print(
                f"[cred-guard] BLOCKED: looks like a hardcoded {label}. "
                f"Factory rule: secrets never appear as literals in code. "
                f"Pull this from the line's configured cred source instead.",
                file=sys.stderr,
            )
            sys.exit(2)  # non-zero → Claude Code blocks the action

    sys.exit(0)

if __name__ == "__main__":
    main()
