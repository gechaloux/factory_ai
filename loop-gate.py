#!/usr/bin/env python3
"""
loop-gate.py - the deterministic line-loop (Stop + SubagentStop hook).

This is the factory's ORCHESTRATION component: the code that runs the loop. Per the SDLC model,
verification is not the agent's judgment - the harness runs the success-criteria suite, captures
failures, routes them back to the model, and decides whether to continue. This hook makes that
deterministic: a line in build cannot be declared "done" until its eval suite (deterministic tests
+ rubric/judge evals) is green.

How it works (fires whenever the agent or a subagent tries to stop):
  1. Find the line (.factory marker). Not in a line, or not in build -> allow stop (exit 0).
  2. Run the line's eval suite (the `eval_cmd` recorded in .factory by eval-scaffold).
  3. GREEN (exit 0) -> mark the line local-done, reset the loop counter, allow stop.
  4. RED (non-zero) -> BLOCK the stop and route the captured failures back to the model with a
     directive to fix them and continue. This is the "return to start if not complete" edge.
  5. BOUNDED: an iteration cap (loop_max) stops a runaway loop from burning tokens forever - on
     exceed, allow stop but emit an escalation notice (a standalone line surfaces it to the
     developer; a child line's subagent returns it to the foreman as a blocked result).

The loop DEFINITION is deterministic; the suite it runs may include non-deterministic evals
(LM judges with rubric thresholds) - that split is intentional. The foreman never runs this loop;
it only sets the done criteria (the suite) in the subcontract.

Fail-OPEN by design: any error in this hook allows the stop. A buggy gate must never imprison the
agent in an unbreakable loop.
"""

import sys, os, json, subprocess, re

DEFAULT_LOOP_MAX = 8          # iteration cap when not set per-line in .factory
SUITE_TIMEOUT_SEC = 1200      # don't let a hung suite wedge the loop

# Statuses at which the loop is active (build phase). Anything else -> don't gate.
BUILD_STATUSES = {"ready-to-build", "building"}


def find_line_root(cwd):
    # Walk up to the .factory marker. Terminate on dirname(d) == d so this works on Windows
    # ('C:\\') as well as POSIX ('/') - a 'd != "/"' guard loops forever on Windows.
    d = os.path.abspath(cwd)
    while True:
        if os.path.exists(os.path.join(d, ".factory")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def read_factory(root):
    fields = {}
    try:
        with open(os.path.join(root, ".factory")) as f:
            for ln in f:
                if ":" in ln and not ln.strip().startswith("#"):
                    k, v = ln.split(":", 1)
                    fields[k.strip()] = v.split("#", 1)[0].strip()
    except Exception:
        pass
    return fields


def set_status(root, new_status):
    path = os.path.join(root, ".factory")
    try:
        lines = open(path).read().splitlines()
        out, seen = [], False
        for ln in lines:
            if ln.strip().startswith("status:"):
                out.append(f"status: {new_status}")
                seen = True
            else:
                out.append(ln)
        if not seen:
            out.append(f"status: {new_status}")
        open(path, "w").write("\n".join(out) + "\n")
    except Exception:
        pass


def read_iter(root):
    try:
        return int(json.load(open(os.path.join(root, "evals", ".loop-state.json"))).get("iterations", 0))
    except Exception:
        return 0


def write_iter(root, n):
    try:
        os.makedirs(os.path.join(root, "evals"), exist_ok=True)
        json.dump({"iterations": n}, open(os.path.join(root, "evals", ".loop-state.json"), "w"))
    except Exception:
        pass


def allow_stop():
    sys.exit(0)


def block_stop(reason):
    # Stop/SubagentStop: top-level decision=block prevents the stop and feeds `reason` to the model.
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(0)


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        allow_stop()  # malformed payload -> never trap the agent

    cwd = payload.get("cwd") or os.getcwd()
    root = find_line_root(cwd)
    if not root:
        allow_stop()  # not inside a line

    fields = read_factory(root)
    status = fields.get("status", "")
    if status not in BUILD_STATUSES:
        allow_stop()  # interview / scaffold / already done -> not the loop's business

    eval_cmd = fields.get("eval_cmd", "")
    if not eval_cmd or eval_cmd == "unset":
        # Nothing to gate against deterministically. Allow stop, but say so loudly - a build line
        # with no suite means the loop has no stopping condition and is running on vibes.
        print(
            "[loop-gate] No eval_cmd in .factory - the line has no deterministic stopping condition. "
            "eval-scaffold should emit the eval suite. Allowing stop, but this line is unverified.",
            file=sys.stderr,
        )
        allow_stop()

    try:
        loop_max = int(fields.get("loop_max", DEFAULT_LOOP_MAX))
    except ValueError:
        loop_max = DEFAULT_LOOP_MAX

    # Run the success-criteria suite against the standing analog.
    try:
        proc = subprocess.run(
            eval_cmd, shell=True, cwd=root, capture_output=True, text=True, timeout=SUITE_TIMEOUT_SEC
        )
    except subprocess.TimeoutExpired:
        # A hung suite is a failure of the build, not a reason to imprison the agent - surface it.
        write_iter(root, 0)
        print(f"[loop-gate] eval suite timed out after {SUITE_TIMEOUT_SEC}s - treating as not-done; "
              f"investigate the suite/analog. Allowing stop.", file=sys.stderr)
        allow_stop()
    except Exception as e:
        print(f"[loop-gate] could not run eval_cmd ({e!r}); allowing stop.", file=sys.stderr)
        allow_stop()

    if proc.returncode == 0:
        # GREEN -> done. Reset the counter and let the agent stop.
        set_status(root, "local-done")
        write_iter(root, 0)
        print("[loop-gate] eval suite GREEN - line meets its success criteria. Local-done.",
              file=sys.stderr)
        allow_stop()

    # RED -> not done.
    n = read_iter(root) + 1
    write_iter(root, n)

    output = ((proc.stdout or "") + "\n" + (proc.stderr or "")).strip()
    output = re.sub(r"\n{3,}", "\n\n", output)[-4000:]  # keep the tail; bound the feedback size

    if n >= loop_max:
        # Bounded: stop the runaway. Escalate rather than spin (cost is a HIGH dimension).
        write_iter(root, 0)
        print(
            f"[loop-gate] eval suite still RED after {n} iterations (cap {loop_max}). Stopping the "
            f"loop to avoid runaway cost. ESCALATE: a standalone line surfaces this to the developer; "
            f"a child line returns a BLOCKED result to the foreman (not a developer question). "
            f"Last failures:\n{output}",
            file=sys.stderr,
        )
        allow_stop()

    block_stop(
        f"The line's eval suite is NOT green (iteration {n}/{loop_max}). You cannot finish until it "
        f"passes - this is the deterministic line-loop, not a suggestion. Read the failures below, fix "
        f"the build (do not weaken the suite to pass it), then continue. If you have concluded the "
        f"CONTRACT itself is wrong (not the build), say so explicitly instead of looping.\n\n"
        f"--- eval suite output (`{eval_cmd}`), tail ---\n{output}"
    )


if __name__ == "__main__":
    main()
