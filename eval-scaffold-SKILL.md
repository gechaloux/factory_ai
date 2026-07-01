---
name: eval-scaffold
description: >
  Infer the verification weight vector for a line from its ratified SPEC.md, SHOW the inference
  and reasoning to the developer, and wait for confirmation or override before committing it.
  Then scaffold eval files for ONLY the raised dimensions. Use after spec-interview ratifies the
  contract and before the build loop starts. This sets the loop's stopping condition, so it is a
  human-in-the-loop gate, not a silent step.
---

# eval-scaffold — the rubric, inferred then confirmed

This skill produces the inner-loop rubric: a weight vector over fixed verification dimensions.
Verification is not a depth dial you turn down — it is these dimensions, reweighted per line.
The skill infers the weights from the ratified contract, but it does NOT commit them silently.
It shows its reasoning and waits, because a wrong weight vector silently mis-sets the loop's
stopping condition — and wrong-but-runs is the developer's worst failure mode.

## The dimensions (fixed)
- correctness: is the output right? (silent-wrong propagates into later lines)
- regression: did a fixed thing re-break? (fed automatically by the burn-detection hook)
- cost: token/retry efficiency
- disruption: can verification break something real?
- trajectory: is the process auditable?
- reproducibility: same input → same output across runs?

## Defaults (these rarely move)
- correctness: HIGH
- regression: HIGH
- cost: HIGH
- trajectory: LOW
- reproducibility: LOW (bumps to MED only when a line graduates to reuse)

## The one signal-driven knob: disruption
Disruption is the dimension you actually infer per line. It tracks the line's shape, because the
shape defines what the analog is and therefore what verification can break:
- shape: docker-analog or local-only → disruption LOW. The analog is disposable; fail loud and
  cheap; do NOT scaffold sandboxing or defensive-failure tests. The PR + CI gate owns real disruption.
- shape: aws-dev-analog → disruption MED-to-HIGH. Verification touches real (non-prod) resources,
  so the dev-stage checks become load-bearing: confirm clean apply, confirm teardown, guard against
  orphaned resources.
- Override up regardless of shape if the contract reveals real blast radius the shape didn't capture
  (e.g. a docker-analog line that also reads from a real production datastore). This is exactly the
  kind of thing to raise in the confirmation, since inference can miss it.

## Re-invocation by a contract amendment
This skill also runs when the as-built conformance check (Path 1) escalates a contract amendment and
the developer re-ratifies it. A changed contract can change what "done" means, so re-read the amended
SPEC.md and re-run the inference + confirmation gate on any weights the change affects. Don't silently
carry forward the old weight vector across a contract change.

## Steps

1. Read the ratified SPEC.md and .factory (shape, target, services). Read the four signals:
   - declared type / target (local-only, tool, deploys)
   - reuse intent (will future lines import this?)
   - determinism (which "Done means" items are code-checkable vs. judgment calls?)
   - blast radius (does verification touch anything real, beyond the analog?)

2. Compute the weight vector. correctness/regression/cost stay HIGH. Set disruption from shape,
   adjusted by any real blast radius the contract reveals. Bump reproducibility only if reuse intent
   is clearly yes.

3. SHOW the developer the inference AND the reasoning, in plain language. Example:
   "Read this as: internal tool, single-user, local, docker-analog, nothing live. So:
   correctness/regression/cost HIGH (defaults), disruption LOW — I'll verify the data is right but
   won't build sandboxing or graceful-failure handling, since a local prototype crashing is cheap.
   trajectory/reproducibility LOW. Sound right, or is there blast radius I'm missing?"
   Then WAIT. This is the confirmation gate — the second of the three human gates.

4. Apply the developer's confirmation or override. A likely override is one sentence ("it'll read
   the real roster DB read-only") → raise disruption. Adjust and re-show only if the change is material.

5. Scaffold evals/ for ONLY the raised dimensions, mapped from "Done means":
   - For each code-checkable "Done means" item → a correctness TEST (deterministic, checked by code).
   - For each non-deterministic "Done means" item → an LM-judge EVAL with an explicit rubric AND a
     numeric pass threshold (what "good" means, and the score it must clear). An eval without a clear
     rubric+threshold measures nothing. Tests verify the deterministic parts; evals verify the rest —
     a line needs both, and together they are the loop's success criteria.
   - If disruption is raised → add the apply/teardown/orphan checks appropriate to the shape.
   - Do NOT scaffold trajectory or reproducibility checks unless those were raised.
   Leave a regressions/ subfolder — empty. The burn-detection hook writes into it during the loop.

5b. Emit the SUITE RUNNER — the deterministic stopping condition. Write evals/run.sh (or a per-stack
   equivalent) that runs every scaffolded check (tests + evals against their thresholds + any raised
   regression and disruption checks) and EXITS NON-ZERO IF ANY FAILS, zero only if all pass. This
   runner — not the agent's judgment — is what decides "done". The loop-gate Stop/SubagentStop hook
   runs it every time the agent tries to finish: green → local-done; red → the failures are routed
   back and the agent must iterate; bounded by loop_max so a stuck loop escalates instead of burning
   tokens. The runner assumes the analog is already standing (the shape's apply.sh stands it up once at
   build start); include apply in the runner only for lines where a change requires re-apply to be
   checked (e.g. IaC lines). Keep it fast and idempotent — it runs on every loop turn.

6. Write into .factory: the confirmed weights, eval_cmd (the command the loop-gate runs, e.g.
   `bash evals/run.sh`), loop_max (the iteration cap; default 8, lower it for cheap lines), and
   status=ready-to-build. Then report what was scaffolded and — equally important — what was
   deliberately NOT scaffolded and why (the cost saving is a design choice the developer should see).
   For a true run-once throwaway with no meaningful checks, say so and leave eval_cmd unset — the
   loop-gate will allow stop but flag the line as unverified, which is the honest state.

7. Seed the line memory. If the line persists (target: deploys, or any line likely to be revisited —
   NOT a true run-once throwaway), create CONTEXT.md seeded from the contract's key decisions: the
   chosen approach and why, the shape and why, any constraints surfaced in the interview, and the
   rejected alternatives the interview considered (so a future run doesn't re-propose them). For a
   disposable local-only line, skip it or leave a one-line stub — there is no future run to educate.
   The loop appends to this file as it works; the developer never maintains it.

## Rules
- Never commit weights without showing the inference and getting confirmation.
- correctness, regression, cost are HIGH on every line — never infer these down. Disruption is the knob.
- Every eval stub maps to a specific "Done means" item. No speculative evals.
- Every non-deterministic eval must state its rubric AND a numeric pass threshold. No rubric = no eval.
- Always emit the suite runner and record eval_cmd in .factory — it is the line's deterministic
  stopping condition, the thing the loop-gate runs. A build line with no runner has no real "done".
- Name what you did NOT verify and why — the omission is the lever, and it should be visible.
