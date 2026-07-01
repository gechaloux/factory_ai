# Factory — global operating rules

This file is the invariant layer. It is loaded into every line (project) automatically.
It defines how the factory works, not what any single line does. Domain-specific rules
live in a line's own CLAUDE.md, never here. Keep this file small and high-signal.

## What this is
A personal prototyping factory. The unit of work is a "line" — one prototype, instantiated
from a shape template under ~/.claude/shapes/. The factory turns an interviewed contract
into infrastructure-as-code, verifies it against a local analog of the deploy target, and
routes the validated artifact through a PR into CI/CD.

The orchestration layer is Claude Code itself. These rules steer it; they do not replace it.

## The lifecycle (every line follows this)
1. Interview the developer to produce a ratified SPEC.md contract. Do not start from an
   assumption that the developer knows every element up front — the interview is how intent
   becomes a contract. Ask few, sharp questions, one at a time. Propose the spec only when
   the "Done means" block can be written unambiguously. The developer ratifies it.
2. Infer a verification weight vector from the ratified spec, SHOW the inference and the
   reasoning, and wait for the developer to confirm or override before committing it.
3. Run the loop: generate against the contract; the harness — not the agent's judgment — verifies.
   The loop is a DETERMINISTIC orchestration component (the loop-gate Stop/SubagentStop hook): when
   the agent tries to finish, the harness runs the line's eval suite (deterministic tests + rubric/
   judge evals), and on red it routes the failures back and forces another iteration. The loop
   DEFINITION is deterministic even though some evals use judges; the agent cannot self-declare done.
   Bounded by an iteration cap so a stuck loop escalates instead of burning tokens.
4. Local "done" = the eval suite is GREEN (the analog stands up and behaves per "Done means"). The
   foreman never runs this loop — it only sets the success criteria (the suite) in the subcontract;
   the line's harness self-terminates on green and the subagent returns that verdict.
4b. As-built + conformance check (persisting lines): generate the as-built doc from what shipped,
    then check it against the contract. MATCH → proceed. Build deviated wrongly → back to the loop
    (autonomous). Contract turned out wrong/incomplete → escalate to the developer to amend +
    re-ratify (re-enters gate 1), then re-check the weight vector. Never silently amend the contract
    to match what got built. For deploys lines this runs BEFORE /submit.
5. If the line deploys: /submit opens a PR with the plan output. The developer reviews the PR.
   This is the gate for anything that touches a real system.
6. Merge runs CI/CD to production. Then /retro and /promote.

## The three human gates (and only these)
- Ratify the contract (step 1) — also where a Path-1 as-built amendment re-enters (re-ratify the change)
- Confirm the weight vector (step 2) — also re-run when a Path-1 amendment changes the contract
- Approve the PR (step 5)
Everything between runs hands-off in orchestrator mode. Do not insert other approval prompts. The
as-built conformance check (step 4b) is autonomous when the build is what's wrong (back to the loop);
it only reaches the developer when the CONTRACT is what's wrong, which is gate 1 by another door.

## Line memory (CONTEXT.md) — prevents cross-session burn
Each persisting line carries a CONTEXT.md: its durable memory, written BY the loop and read BY the
loop, never maintained by the developer. It exists to stop a future run from re-walking ground an
earlier run already covered — re-deriving a settled decision, re-proposing a rejected approach, or
re-introducing a fixed bug because nothing recorded WHY the code is the way it is. The burn hook
catches a failure repeating within a run; CONTEXT.md catches the loop repeating old ground ACROSS
runs (cross-session amnesia). It is the persistent-memory half of the line's context.

Rules for CONTEXT.md:
- Read it FIRST on every loop run — it is static context for the line, loaded like the line CLAUDE.md.
- Write to it as the loop goes: consequential decisions + their rationale, approaches tried and
  REJECTED (and why, so they aren't re-proposed), discovered constraints/gotchas, and the WHY behind
  every crystallized regression (the test lives in evals/; the reason lives here).
- Record only what is NOT recoverable from the code or spec. It is not a summary of what the code
  does — the code says that. It is the reasoning, dead ends, and landmines that reading the code
  won't reveal.
- The developer never has to touch it. If a line is a true throwaway (local-only, run-once) it can
  be minimal or absent — there is no future run to educate. Depth is proportional to whether the line
  persists: light/absent for disposable, accreting for durable (deploys, graduating, revisited) lines.


Verification is not a depth dial. It is a fixed set of dimensions, reweighted per line:
- correctness: HIGH by default — wrong-but-runs output is the worst failure; it propagates silently.
- regression: HIGH by default — fed automatically by the burn-detection hook.
- cost: HIGH by default — token/retry efficiency.
- disruption: inferred from blast radius. LOW when the analog is disposable (local/Docker);
  raised only when verification touches real resources (e.g. an AWS-dev analog) or live systems.
- trajectory: LOW unless a line explicitly needs process auditing.
- reproducibility: LOW until a line graduates to reuse.
Spend the scrutiny budget on correctness/regression/cost. Do not spend it on disruption
safety (sandboxing, defensive failure handling) for disposable local analogs — fail loud and
cheap there. The PR + CI gate owns real-world disruption.

## The technology standard
~/.claude/stack.md is the factory's TECHNOLOGY standard — the parts the factory reaches for
(backend, frontend, persistence, etc.), each with a default and a deviation rule. It is not
pre-decided; it accretes from real lines via the add-stack-part skill (developer-confirmed). The
Phase-1 interviewer reads it first and only asks about layers it is silent on — so the recurring
"which stack" question is answered once, here, not per line.

Keep two things separate, the way enterprises do:
- TECHNOLOGY standard = which parts. Lives in stack.md as defaults + deviation rules.
- CODING standard = how to write within a part. Lives in each line's lint/format config and is
  ENFORCED by the code-ci merge gate, never written as prose. The linter is the source of truth;
  prose conventions drift from it and lose. Never record coding conventions in stack.md.
Together with the shape templates and the workflow, stack.md makes the factory a paved road, not a
document people are meant to follow.

## Tiers: factory, program, line
- The FACTORY (~/.claude) is invariant — built once, refined via /promote.
- A LINE (~/prototypes/<name> or under a program) is one prototype: one coherent contract + loop.
- A PROGRAM (~/prototypes/<program>) is app-scale intent too big for one line — a system of connected
  lines. It is owned by the FOREMAN, which establishes a program contract (shared data model, stack,
  design system, the child lines, the SEAMS between them, and the build order), gets it ratified ONCE,
  then decomposes into a dependency graph and runs the child lines itself by spawning a SUBAGENT per
  child (its delegate) that calls new-line — threading the shared contract, holding the seams frozen,
  and running a program-level integration check at the end. The foreman orchestrates; it does not
  build lines inline. After ratification it runs HANDS-OFF: no developer questions except a contract
  change order or a PR approval — line-local decisions are resolved autonomously or become change
  orders (a mid-build pause for the developer is a bug). The developer communicates intent at the
  program level and does NOT hand-create lines; that delegation is the factory's purpose at app scale.

When intent is too big for one line (e.g. a whole-app Claude Design handoff), it is a program: hand to
the foreman (/program), never ask the developer "which line first?" — derive order from the graph.
Seams are frozen contracts between lines; a line changing a seam is a change order to the foreman, not
a unilateral act. The foreman is autonomous WITHIN the ratified program contract and BEHIND the PR
gates — it runs lines but cannot change the contract or touch prod without the developer. (Stage 1 runs
lines serially in dependency order; parallelism within a layer is a later stage the graph already encodes.)

## Line shapes
A shape is defined by its analog — what stands in for production during local verification,
and therefore what disruption costs before the PR gate. The shape is only the middle of the
lifecycle; everything up- and downstream is shared.
- docker-analog: verify against a disposable Docker/LocalStack stand-in. Cheap, fenced, fast.
  Default for most lines. Invalid when the analog can't faithfully represent what the line needs
  (e.g. IAM assume-role chains, real networking, managed-service semantics, scale).
- aws-dev-analog: verify against a real non-prod AWS account. Faithful but slower, not free,
  not fully disposable — disruption rises and the dev-stage eval becomes load-bearing.
- local-only: never deploys, never opens a PR. Ends at local "done" as a running container.
During the interview, surface which shape fits and have the developer confirm it.

## Hard rules (all lines inherit)
- Never hardcode secrets. Creds come from a configured source per line, never literals in code.
- Deploying lines emit IaC (Terraform/CloudFormation), not direct API calls. The IaC artifact
  is dual-purpose: it applies to the local analog and is what the PR submits. Same artifact both sides.
- The same IaC that was validated against the analog is what crosses the PR gate. No rewrite for cloud.
- Nothing reaches a real system without crossing the PR gate.

## The compounding rule
Anything explained or corrected twice across lines gets promoted to this factory layer
(a skill, a rule here, a hook). First time in a line = per-line. Second time across lines = global.
/retro surfaces candidates; /promote graduates them. Domain logic stays in the line and never
graduates — only reusable mechanism does. This is the one discipline that makes the floor faster
every run instead of sprawling.

## Output conventions
- Prose over decoration. Minimal formatting unless a line asks otherwise.
- Be skeptical of clever code. Verify imports resolve to real packages. Check error handling
  covers realistic paths for the line's stakes.
