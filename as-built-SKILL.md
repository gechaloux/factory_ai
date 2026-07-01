---
name: as-built
description: >
  Run at local-done for any persisting line (and before /submit for deploys lines). Does two jobs:
  (1) generates a human-readable as-built doc (README.md/DESIGN.md) describing what ACTUALLY shipped,
  regenerated from reality; (2) runs the as-built against the ratified contract as a CONFORMANCE
  CHECK and routes the result — match → proceed; build deviated wrongly → back to the loop
  (autonomous); contract turned out wrong → escalate to the developer to amend + re-ratify. This is
  the closing verification edge that keeps build and contract in agreement. Skip for true throwaways.
---

# as-built — documentation that is also a verification edge

This runs when a line reaches local-done. It is NOT a plan (forward, human-approved) — it is an
as-built (backward, generated from what shipped, true by construction). And it is not passive: the
as-built compared against the contract is itself a check on whether the build matches what was agreed.

## Skip condition
True run-once throwaway (local-only, no future reader, high deviation tolerance): skip. There is no
human downstream and no contract to hold the build to. The as-built earns its place on persisting
lines — deploys, graduating, revisited — and on any line whose tolerance is low/zero.

## Job 1 — generate the as-built (regenerate, never append)
Synthesize a human-readable doc (README.md, or DESIGN.md if a README already serves another purpose)
in PAST tense — what this is and does, not what it should do. Regenerate it from current reality each
time done is reached; do not edit-in-place an old one (that reintroduces the stale-README problem).
Source it from:
- the ratified SPEC.md (intent + "Done means") — restated as "does", not "should"
- the shipped IaC/src — the actual architecture, components, data flow, what deploys where
- CONTEXT.md — distill ONLY the load-bearing decisions worth a human knowing (not the full dead-end log)
Contents: what it is + does; the shape and actual shipped architecture; how to run/operate it (analog
commands, deploy path, env/secrets expected); key decisions a human should know; verification posture
(which weights were raised, what the evals actually check). Its value is the DELTA between intended
and actual — surface where reality diverged from the spec, don't just copy the spec forward.

## Job 2 — conformance check (as-built vs contract) and routing
Compare the as-built (reality) against the ratified contract (SPEC.md "Done means" + intent). Then
route by the result. There are exactly THREE outcomes and the third is forbidden:

- MATCH → the build satisfies the contract. Proceed (to /submit for deploys, or done for local-only).

- BUILD DEVIATED WRONGLY (the contract was right; the build doesn't meet "Done means") →
  Path 2. Go BACK TO THE LOOP. This is autonomous — it just means "not actually done yet, the
  stopping condition wasn't really met." Record the gap in CONTEXT.md and re-run the loop to conform.
  No developer needed.

- CONTRACT TURNED OUT WRONG/INCOMPLETE (the build is correct; the contract didn't foresee something —
  a constraint, a better approach, an underspecified "Done means") → Path 1. ESCALATE to the
  developer. Propose the specific contract amendment with reasoning. The developer must re-ratify the
  changed contract (a contract amendment is a re-signing — it re-enters the ratify gate, which is
  theirs). On re-ratification, hand back to eval-scaffold to RE-CHECK the weight vector — a changed
  contract can change what "done" means.

- FORBIDDEN third outcome: silently amending the CONTRACT to match what got built. The as-built is
  derived from what shipped, so it always matches the build — the thing that can be falsified is the
  contract. Quietly rewriting SPEC.md so the divergence disappears (making the contract retroactively
  "always want" whatever the build did) erases the divergence, makes the contract a lie, and passes
  verification against a moved goalpost — the documentation form of "wrong-but-runs". A divergence
  must always resolve to Path 1 (developer-confirmed amendment + re-ratify) or Path 2 (fix the build),
  never to silently moving the contract to wherever the build landed.

## Job 2b — build-vs-handoff (only when a handoff acceptance suite exists)
If the line was seeded from a Claude Design handoff, `evals/handoff-acceptance/` holds the retained
bundle + the acceptance suite import-handoff derived. Job 2 checks build-vs-CONTRACT; this checks
build-vs-HANDOFF — a distinct axis, because the handoff→contract distillation is lossy and a faithful
build of a contract that silently dropped a screen or flow passes Job 2 green. This is the only edge
that catches a faithful build of an unfaithful contract.

Run the acceptance suite under the PRESENT-OR-ACCOUNTED-FOR rule — NOT pixel-match. Each handoff
element (screen, documented flow, key behavior/copy, token) is satisfied if it is present in the build
OR explicitly accounted for by a recorded decision in SPEC.md / CONTEXT.md. The frontend is a seed,
not settled architecture, so deliberate divergence is allowed; only unaccounted-for loss fails. Route
each divergence into the SAME three outcomes as Job 2:
- present, or deliberately diverged and recorded → MATCH on this axis. Proceed.
- handoff element missing AND the build also doesn't meet "Done means" for it → Path 2 (build deviated,
  back to the loop, autonomous).
- handoff element missing but the build faithfully matches the CONTRACT — i.e. the contract itself
  dropped it → Path 1. This is the lossy-distillation catch: the contract turned out incomplete.
  ESCALATE to the developer to amend + re-ratify (then eval-scaffold re-checks weights). NEVER silently
  amend the contract or quietly drop the handoff element to make the divergence disappear — same
  forbidden move as Job 2.
Both axes must be MATCH (under their tolerance) before the line proceeds past done.

## How tolerance gates the routing
Read deviation-tolerance from .factory:
- HIGH tolerance: minor divergences are Path-1-pre-approved — document them in the as-built and
  proceed without stopping the developer. Only escalate material divergences. (Exploratory lines.)
- LOW / ZERO tolerance: any divergence from "Done means" escalates (Path 1) or routes back (Path 2).
  Nothing minor gets waved through. (Exact lines, typically deploys/aws-dev.)
The asymmetry holds regardless of tolerance: Path 2 (fix the build to match the contract) is always
autonomous; Path 1 (change the contract to match reality) always requires the developer, because the
contract is theirs to sign.

## Placement in the lifecycle
- Persisting line reaches local-done → run this.
- deploys line: run this BEFORE /submit, so the as-built is in the repo for the PR review and the
  conformance check has already passed before anything crosses the PR gate.
- If it routes to Path 2, the loop runs again and this re-runs at the next done.
- If it routes to Path 1, the developer re-ratifies, eval-scaffold re-checks weights, then this re-runs.

## Rules
- Regenerate from reality; never edit an old as-built in place.
- Past tense — describe what shipped, not what was intended.
- The conformance check has three outcomes; silently amending the contract to match the build is forbidden.
- When a handoff acceptance suite exists, check build-vs-handoff too (Job 2b) — it is the only edge
  that catches a faithful build of an unfaithful contract. Present-or-accounted-for, same three
  outcomes, same forbidden silent-amend.
- Path 2 autonomous, Path 1 to the developer — never amend a contract without re-ratification.
- A Path 1 amendment re-triggers the weight-vector check.
