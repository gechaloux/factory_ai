# The factory

A personal prototyping factory built on Claude Code. It turns an interviewed contract into
infrastructure-as-code, verifies that IaC against a disposable local analog of the deploy target,
and routes the validated artifact through a PR you approve into a CI/CD deploy.

Claude Code is the orchestration layer. None of this builds an agent loop — it configures the one
you already have. The net-new work is policy and three skills; everything else plugs into Claude
Code's existing slots.

## Install
    ./install.sh            # macOS/Linux; lays files into ~/.claude (set CLAUDE_HOME to override)
    .\install.ps1           # Windows PowerShell; same layout into ~\.claude

Both installers back up any preexisting core file (CLAUDE.md, settings.json) with a timestamp before
overwriting, so a re-install always updates you and the old version is recoverable. stack.md is the
exception — it accretes your real tech standard over time, so an existing one is KEPT, never clobbered
(only the empty template installs when stack.md is absent).

On Windows: the factory brain (skills, Python hooks, commands, workflow) is OS-agnostic. Only the
shape analog scripts (apply.sh / bootstrap.sh / teardown.sh) are bash — run those under WSL or Git
Bash, which is where Docker/Terraform/AWS work typically lives on Windows anyway.

Then create the floor:
    mkdir -p ~/prototypes

## The lifecycle (every line)
1. /new-line <name> "<one-liner>"     scaffold + hand to the interview
2. interview                          intent → ratified SPEC.md contract        [gate 1: you ratify]
3. eval-scaffold                      infer weight vector, show reasoning        [gate 2: you confirm]
4. build loop                         generate → loop-gate runs the eval suite → red routes failures back, green = done
5. burn-detect                        repeats crystallize into regression checks (automatic)
6. local done                         the eval suite is green (analog stands up + behaves per "Done means")
6b. as-built + conformance            generate as-built from what shipped; check vs contract:
                                        match→proceed · build wrong→loop (auto) · contract wrong→
                                        amend + re-ratify (gate 1) → re-check weights
7. /submit  (deploys only)            PR with plan output                        [gate 3: you approve PR]
8. PR checks (all required to merge)  code-ci + ai-review + infra-plan must pass before merge
9. merge → CI/CD                      apply to prod (gated behind all three checks)
10. /retro + /promote                 graduate reusable mechanism to the factory

Three human gates, nothing else: ratify the contract, confirm the rubric, approve the PR.
On the PR itself, three MACHINE gates run and all must pass before you can merge: deterministic
code CI (lint/typecheck/tests+evals), AI first-pass diff review, and infra plan/scan.

## File map (where install.sh puts things)
    ~/.claude/CLAUDE.md                          invariant factory law
    ~/.claude/stack.md                           technology standard (which parts; accretes per line)
    ~/.claude/settings.json                      orchestration controls (hooks + routing)
    ~/.claude/skills/new-line/SKILL.md           line generator
    ~/.claude/skills/spec-interview/SKILL.md      Phase-1 interviewer (produces the contract)
    ~/.claude/skills/eval-scaffold/SKILL.md       Phase-2 weight vector (the rubric) + confirm gate
    ~/.claude/skills/add-stack-part/SKILL.md      amend the tech standard from a line (confirmed)
    ~/.claude/skills/as-built/SKILL.md            as-built doc + contract-conformance check at done
    ~/.claude/skills/import-handoff/SKILL.md      handoff front door: infer line vs program, route the bundle
    ~/.claude/skills/foreman/SKILL.md             owns a PROGRAM: decompose → delegate lines → integrate
    ~/.claude/commands/program.md                start an app-scale program (hands to the foreman)
    ~/.claude/commands/retro.md                  surface promotion candidates
    ~/.claude/commands/promote.md                graduate a candidate to the factory
    ~/.claude/commands/submit.md                 open the PR (deploy gate)
    ~/.claude/hooks/burn-detect.py               regression ratchet (PostToolUse)
    ~/.claude/hooks/cost-log.py                  observability (PostToolUse)
    ~/.claude/hooks/cred-guard.py                secret-leak block (PreToolUse)
    ~/.claude/hooks/loop-gate.py                 deterministic line-loop (Stop + SubagentStop)
    ~/.claude/shapes/docker-analog/...           default shape: Docker/LocalStack analog
    ~/.claude/shapes/aws-dev-analog/...          high-fidelity shape: real non-prod AWS
    ~/.claude/workflows/deploy.yml               reusable CI/CD gate (drops into a deploying line)
    ~/.claude/factory-log.jsonl                  append-only run + promotion log

## Concepts
- Factory vs line: the factory (~/.claude) is invariant, built once, refined via /promote. A line
  (~/prototypes/<name>) is one prototype, instantiated from a shape.
- Shape: defined by its analog — what stands in for prod during local verification, and therefore
  what disruption costs before the PR. docker-analog (disposable, cheap, default), aws-dev-analog
  (real non-prod, faithful, disruption raised), local-only (never deploys). Shape is only the middle
  of the lifecycle; everything up- and downstream is shared.
- Weight vector: the inner-loop rubric. correctness/regression/cost HIGH always; disruption is the
  one inferred knob (low for disposable analogs); trajectory/reproducibility low until earned.
- The compounding rule: anything explained or corrected twice across lines graduates to the factory.
  Domain logic never graduates — only reusable mechanism.
- Technology standard vs coding standard: stack.md holds the TECHNOLOGY standard (which parts —
  defaults + deviation rules), accreting from real lines via add-stack-part. CODING standards (how
  to write) are NOT prose — they're the lint/format config enforced by the code-ci merge gate. The
  interviewer reads stack.md first and only asks about layers it's silent on, so "which stack" is
  answered once, not per line. Stack + shapes + workflow together = a paved road, not a document.
- Line memory (CONTEXT.md): each persisting line carries a durable memory written and read BY the
  loop, never maintained by you. Two anti-burn mechanisms work together: the burn hook catches a
  failure repeating WITHIN a run and crystallizes a regression test; CONTEXT.md catches the loop
  repeating old ground ACROSS runs (re-deriving settled decisions, re-proposing rejected approaches,
  re-introducing fixed bugs) by recording the why that the code can't show. Read first, appended as
  the loop works, seeded by eval-scaffold. Minimal/absent for true throwaways; accreting for durable lines.
- As-built + conformance: at done, persisting lines generate a human-readable as-built (what ACTUALLY
  shipped, regenerated from reality, past tense) — and that as-built is checked against the contract.
  Three outcomes only: match → proceed; build deviated wrongly → back to the loop (autonomous);
  contract turned out wrong → escalate to amend + re-ratify (gate 1), then re-check the weight vector.
  Silently amending the contract to match what got built is forbidden — the as-built is derived from
  the build so it always matches; the contract is the thing that can be falsified, and moving it to
  wherever the build landed is the documentation-form "wrong-but-runs". Each contract carries a
  deviation tolerance (set in the interview) gating how loud a divergence must be before it stops you.
  Asymmetry: fixing the build to match the contract is autonomous; changing the contract to match
  reality is always yours.

- Factory vs program vs line: the factory (~/.claude) is invariant. A line is one prototype. A PROGRAM
  is app-scale intent too big for one line, owned by the FOREMAN: it establishes a program contract
  (shared data model, stack, design system, the child lines, the SEAMS between them, and the build
  order), the developer ratifies it ONCE, then the foreman decomposes into a dependency graph and runs
  the child lines itself — calling new-line per child, holding the seams frozen, integrating at the
  end. You communicate intent at the program level and never hand-create lines. A whole-app Claude
  Design handoff is a program, not a line. Seams are frozen contracts between lines; a line changing
  one is a change order to the foreman. The foreman is autonomous within the ratified contract and
  behind the PR gates — it can't change the contract or deploy without you. (Stage 1: serial in
  dependency order; same-layer parallelism is a later stage the graph already encodes.)
- Handoff entry path: import-handoff is the SINGLE front door for any Claude Design handoff bundle
  (.tar.gz/.zip). It cracks the bundle (component spec, design tokens, layout, assets, design
  rationale), inventories the screens and the data entities/flows the frontend implies, and INFERS
  whether the design is one line or a whole program — the developer does not pre-declare the tier. A
  single feature routes to a line (new-line scaffolds it, frontend → src/frontend/, rationale →
  CONTEXT.md, then the interview covers the GAPS: backend, persistence, target, shape, "Done means").
  A whole app routes to a program (the foreman; tokens → the program design system, implied entities →
  the shared data model, established once). `/new-line --from-handoff` and `/program --from-handoff`
  are sugar that funnel through import-handoff, so the flag is a hint, not a binding tier choice. The
  tier inference is autonomous (surfaced, not a gate — ratification is the gate). The frontend is a
  strong seed for the WHAT — not settled architecture, not production-ready, not exempt from
  verification or the as-built check. The design tokens become the styling source of truth.

## What you still need to wire (intentionally left open)
- settings.json routing: this block is a documentation PLACEHOLDER, not a native Claude Code setting —
  nothing in the harness reads it. It records the intended model tiering (frontier for judgment, local
  for deterministic bulk); enforce it through skills/prompts, not by expecting Claude Code to honor it.
- cred source: cred-guard blocks hardcoded secrets but doesn't dictate where creds come from —
  that's a per-line choice. No broker is assumed.
- workflows/deploy.yml: set PROD_DEPLOY_ROLE_ARN secret + AWS_REGION var, set ANTHROPIC_API_KEY
  secret (for the AI review job), and wire your IaC scanner (checkov/tfsec/conftest) into the scan
  step. Uses OIDC — no long-lived keys in CI. Also fill the code-ci placeholders (lint/typecheck/
  test commands) for the line's stack.
- Required checks (one-time per repo): the workflow runs code-ci, ai-review, and infra-plan, but
  GitHub only BLOCKS a merge if they're marked required. In repo Settings → Branches → branch
  protection on main, enable "Require status checks to pass before merging" and select all three
  job names. Without this, the checks run but a merge isn't actually gated on them.
- shapes: docker-analog mocks a default service set; trim/extend per line via the `services` field.

## Build order if you ever rebuild from scratch
global CLAUDE.md → new-line → spec-interview → eval-scaffold + burn-detect → docker-analog →
deploy.yml → retro + promote. Add aws-dev-analog the first time a line's fidelity demands it.
#   f a c t o r y _ a i  
 