#!/usr/bin/env python3
"""
burn-detect.py — the regression ratchet.

Wired as a PostToolUse hook in ~/.claude/settings.json. It watches the loop for the SIGNATURE
OF REDUNDANT EFFORT: the same class of failure recurring within a line. When it fires, it does
not loop — it ratchets: it records a regression marker so a check gets crystallized into the
line's evals/regressions/ folder. From then on the inner loop verifies against it, so that
specific failure can't silently re-break. This is the mechanism that targets the developer's
sensitivity to redundant effort: you never write regression tests speculatively, but the moment
iteration starts costing repeat work, the lesson is captured automatically.

This is a heuristic detector, deliberately cheap. It flags candidates; it does not block the loop.
The agent, seeing the flag, writes the actual regression check mapped to the failure.

Input: Claude Code passes hook context as JSON on stdin (tool name, args, result, cwd).
Output: on a detected repeat, append a marker to <line>/evals/regressions/.pending.jsonl and
print a short notice the agent will act on. Otherwise exit silently.
"""

import sys, os, json, hashlib, time, re

# How many times the same failure class must recur before we ratchet.
REPEAT_THRESHOLD = 2

def line_root(cwd):
    # The line is the project dir; .factory marks it. Walk up to find it.
    # Terminate on dirname(d) == d — the root condition that holds on both POSIX ('/')
    # and Windows ('C:\\'). Comparing against '/' alone spins forever on Windows, because
    # os.path.dirname('C:/') returns 'C:/' (the drive root is its own parent).
    d = os.path.abspath(cwd)
    while True:
        if os.path.exists(os.path.join(d, ".factory")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent

def failure_signature(payload):
    """
    Reduce a tool result to a stable 'class of failure' fingerprint.
    We hash the normalized error shape, not the exact text, so 'same kind of break' collides
    even when line numbers or values differ.
    """
    result = json.dumps(payload.get("tool_result", ""), default=str).lower()
    # Only care about results that look like failures.
    if not re.search(r"error|fail|assert|traceback|exception|exit code [1-9]", result):
        return None
    # Normalize volatile bits so the same failure class fingerprints identically.
    norm = re.sub(r"0x[0-9a-f]+|line \d+|:\d+|\b\d{3,}\b|/tmp/\S+", "", result)
    norm = re.sub(r"\s+", " ", norm).strip()
    # Keep the most signal-bearing tokens (error type words), bounded.
    tokens = re.findall(r"[a-z_]{4,}", norm)[:40]
    return hashlib.sha1(" ".join(tokens).encode()).hexdigest()[:12]

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # never break the loop on a malformed payload

    cwd = payload.get("cwd") or os.getcwd()
    root = line_root(cwd)
    if not root:
        sys.exit(0)  # not inside a line

    sig = failure_signature(payload)
    if not sig:
        sys.exit(0)  # not a failure

    reg_dir = os.path.join(root, "evals", "regressions")
    os.makedirs(reg_dir, exist_ok=True)
    counts_path = os.path.join(reg_dir, ".counts.json")

    counts = {}
    if os.path.exists(counts_path):
        try:
            counts = json.load(open(counts_path))
        except Exception:
            counts = {}

    counts[sig] = counts.get(sig, 0) + 1
    json.dump(counts, open(counts_path, "w"))

    if counts[sig] >= REPEAT_THRESHOLD:
        marker = {
            "sig": sig,
            "count": counts[sig],
            "ts": time.time(),
            "tool": payload.get("tool_name"),
            "snippet": json.dumps(payload.get("tool_result", ""), default=str)[:500],
        }
        with open(os.path.join(reg_dir, ".pending.jsonl"), "a") as f:
            f.write(json.dumps(marker) + "\n")

        # Cross-session memory: record that this failure class recurred, so a future run
        # understands WHY the regression check exists rather than just obeying it. The test goes
        # in evals/regressions/; the reason goes in CONTEXT.md (the line's durable memory).
        ctx = os.path.join(root, "CONTEXT.md")
        try:
            note = (
                f"\n### regression {sig} (auto-recorded by burn-detect)\n"
                f"- A `{payload.get('tool_name')}` failure of this class recurred {counts[sig]}x.\n"
                f"- A regression check was crystallized in evals/regressions/ to pin it.\n"
                f"- Future runs: do NOT re-debug this loosely — the check guards it. Snippet: "
                f"{json.dumps(payload.get('tool_result', ''), default=str)[:200]}\n"
            )
            with open(ctx, "a") as f:
                f.write(note)
        except Exception:
            pass  # never break the loop on a memory-write failure

        # Notice the agent acts on: write a real regression check for this failure class.
        print(
            f"[burn-detect] failure class {sig} has recurred {counts[sig]}x. "
            f"Crystallize a regression check in evals/regressions/ that pins this specific "
            f"failure, record the WHY in CONTEXT.md, then continue. Do not re-debug it loosely a third time.",
            file=sys.stderr,
        )

    sys.exit(0)

if __name__ == "__main__":
    main()
