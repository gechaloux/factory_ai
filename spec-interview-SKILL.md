---
name: spec-interview
description: >
  Interview the developer to turn a one-liner of intent into a ratified SPEC.md contract.
  Use at the start of every line (invoked by new-line, or directly via /spec). The developer
  does NOT arrive with a finished spec — this interview is how intent becomes a contract. Scope-check
  first (decompose multi-subsystem seeds into separate lines), then ask few sharp questions one at a
  time, apply YAGNI, propose 2-3 approaches with a recommendation for consequential decisions, surface
  the edges the developer hasn't resolved, validate the design in chunks proportional to stakes, then
  draft the spec and get it ratified. Also establishes the line's target and shape.
---

# spec-interview — intent becomes a contract

The premise: the developer does not know every element up front, and shouldn't have to. That is
the whole point of turning intent into code. The interview is collaborative — you are not filling
a form, you are helping the developer discover what they actually want by asking the questions
that expose the ambiguities. The output is a contract both parties sign: you draft it, they ratify.

## First: am I a child line of a program? (autonomous mode — no developer interview)
If this line is a child of a program (invoked by a foreman subagent, with an inherited program
contract + slice + seams), do NOT run the interactive interview below. The contract already exists at
the program level and was ratified ONCE; re-interviewing the developer per child is exactly the pause
the program tier forbids. Run in AUTONOMOUS mode instead:
- Take the inherited shared data model, stack, and design system as GIVEN — do not re-decide or re-ask
  any of them.
- Resolve the line-local delta (its slice + the seams it exposes/consumes) yourself, from the
  inherited contract + ~/.claude/stack.md + YAGNI. Make the reasonable call a delegate would make.
- Write SPEC.md as the delta and proceed straight into the build loop. There is NO per-child
  ratification gate and NO developer interview.
- ONLY if a decision genuinely cannot be made without changing a seam or the program contract: STOP
  and return a CHANGE ORDER to the foreman (what's blocked, why, the options). Never ask the developer
  directly — the foreman owns escalation.
Everything below (the developer interview, the scope-check, per-line ratification) applies to a
STANDALONE line, not a child of a program.

## The technology standard (read this first)

Before asking any stack question, read ~/.claude/stack.md — the factory's technology standard.
- For any layer with a default, ASSUME it. Do not ask the developer about it. This is the point of
  the standard: the recurring "which backend / frontend / datastore" question is already answered.
- Ask about a layer ONLY when it is `unset`, or when the line's needs trip that layer's
  `deviate when` rule.
- When this line decides an `unset` layer, or deviates from a default for a reason that will recur,
  call the add-stack-part skill to amend the standard (developer-confirmed). A one-off choice stays
  in the line and does NOT amend the standard.
- Never record coding conventions in the standard — those are enforced by the line's linter via
  code-ci, not written as prose.

## If the line was seeded from a handoff (import-handoff ran first)

When a Claude Design handoff seeded the line, you arrive with a starting understanding, not a blank
page. LEAD with it: "here's what I can see you've already built" — the screens, components, tokens,
and the data entities / user flows the frontend implies. Confirm your reading, then interview only
the GAPS the frontend can't answer:
- the backend these screens need (the frontend implies endpoints but doesn't define them)
- the persistence behind the implied data model
- target (deploys vs local-only) and shape
- the full "Done means" — the frontend rendering is NOT done; done includes the backend behaving
Treat the frontend as the most concrete part of the seed, never as settled architecture or as
production-ready. The design tokens are the styling source of truth — don't relitigate them.

## Scope check first (decompose into lines before refining)

Before refining details, assess scope. If the seed describes multiple independent subsystems
(e.g. "a platform with chat, file storage, billing, and analytics", or a whole-app Claude Design
handoff), it is a PROGRAM, not a line. Do NOT ask the developer "what do you want to start with?" —
that orphans the rest and offloads sequencing onto the developer, defeating the factory's purpose.
Instead, hand to the foreman (via /program). The foreman establishes a program contract — the shared
model, stack, design system, the child lines, the seams between them, and the build order — gets the
developer to ratify it ONCE, then decomposes and runs the lines itself. The developer communicates
intent at the program level and does not hand-create lines.

Only continue the single-line interview below when the seed genuinely is one coherent line.

## Conduct of the interview

Ask ONE question at a time. Wait for the answer. Let each answer steer the next question — go
deeper where an answer opened something, move on where it closed. Few, sharp questions beat a long
intake. A question earns its place only by resolving a real ambiguity or surfacing an edge the
developer hasn't considered. Do not ask stack questions the standard already answers.

Apply YAGNI ruthlessly. Actively strip features the line doesn't need yet — every speculative
feature is future redundant effort to build, verify, and maintain. When the developer adds scope,
it's fair to ask whether it's needed for THIS prototype or can wait. Bias the contract toward the
smallest thing that's actually useful.

Propose alternatives before settling. For any consequential design decision (not trivial ones),
lay out 2-3 approaches with their trade-offs, lead with your recommendation and say why, and let
the developer choose. Don't silently pick an approach and bake it into the spec — surfacing the
options is where the developer's judgment actually adds value. (Pattern borrowed from superpowers.)

Push on the things the developer is likely to have left implicit. Good probes:
- Who uses this, and how many? (drives auth, multi-user data separation, scale)
- What's the smallest version that's actually useful? (bounds scope, prevents gold-plating)
- For each fuzzy noun in the seed, what does it concretely mean? ("review summary" — point-in-time
  or full history? for the developer to edit, or delivered as-is?)
- What are the inputs and where do they come from? (real data source vs. synthetic)
- What's explicitly out of scope for this prototype?

Surface edges the developer didn't raise. The value of the interview is catching what they'd miss
writing solo. If an answer implies a complication (e.g. "other managers use it too" implies auth
and per-user separation), name it and confirm whether it's in scope.

## Two load-bearing questions you must resolve before drafting

These determine the back half of the line, so the interview is not complete without them:

1. TARGET — does this become infrastructure, or does it live locally?
   - Lives on the developer's machine, never deploys → target: local-only.
   - Becomes deployed infrastructure → target: deploys.

2. SHAPE (only if target: deploys) — what can faithfully serve as the local analog?
   - If a Docker/LocalStack stand-in can faithfully represent what the line needs → docker-analog.
   - If the line leans on things Docker can't represent faithfully (IAM assume-role chains, real
     networking, managed-service semantics, scale) → aws-dev-analog. Say WHY when you propose this:
     "this leans on X, which LocalStack won't represent faithfully, so I'd shape it as aws-dev. Agree?"
   - target: local-only → shape: local-only.
   Propose the shape with your reasoning; the developer confirms or overrides. Don't decide silently.

## Deviation tolerance (set this for lines where it matters)

The as-built conformance check (run at done) compares what actually got built against this contract.
The contract must say how much the build may diverge before the developer wants to be asked. Set it
during the interview for any line where it's consequential (a loose exploratory prototype vs. an
exact deploys line); a sensible default by shape is fine otherwise:
- HIGH tolerance — exploratory/throwaway. "Done means" is loose by design; minor divergences are
  expected and get documented in the as-built and proceed, no escalation. Default for local-only.
- LOW / ZERO tolerance — the contract is exact (typical for deploys, especially aws-dev). Any
  divergence from "Done means" escalates to the developer at done.
Write the chosen tolerance into the contract and .factory. The as-built check reads it to decide how
loud a divergence must be before it stops for the developer.

## Drafting and ratification

Present the design in small, validated chunks rather than one wall of spec — but make the DEPTH
proportional to the line's stakes (this is where the factory differs from a one-size methodology):
- local-only / docker-analog throwaway: a light single pass is enough — the intent, "Done means",
  and the out-of-scope line. Don't subject a disposable prototype to a full architecture review.
- deploys, especially aws-dev-analog: present in sections of ~200-300 words and check after each
  that it looks right so far — covering at least: what it does, data flow, "Done means", failure
  modes that matter, and out-of-scope. Catch divergence early, before the whole contract is drafted.
(Chunked section validation borrowed from superpowers; the depth-gating-by-shape is the factory's
own — it keeps low-stakes lines rapid.)

Propose the full spec ONLY when you can write the "Done means" block unambiguously. Draft SPEC.md:

```
# <name> — intent
<one-paragraph statement of what this is, in concrete terms>

## Done means
- <success criteria, each one verifiable — this is what the rubric checks against>
- ...

## Target & shape
- target: <deploys | local-only>
- shape: <docker-analog | aws-dev-analog | local-only>  (+ one line of why, if aws-dev)
- services: <AWS services the analog must represent, if deploys>
- deviation tolerance: <high | low | zero>  (how much the build may diverge before escalating to me)

## Stack delta
<only what differs from factory defaults; often nothing exotic>

## Out of scope
- <what this prototype deliberately does not do>
```

Show the draft. The developer reads it and corrects what you got wrong. You are not done until they
say it matches their intent — that is the ratification, the first of the three human gates. If they
push back, reopen the relevant questions; don't argue the draft into acceptance.

## On ratification
- Write the ratified SPEC.md into the line.
- Update the line CLAUDE.md "What this is" and "Done means" from the contract.
- Update .factory: status=spec-ratified, target, shape, services, deviation-tolerance.
- Hand off to eval-scaffold for the weight vector (Phase 2). Do not start building — eval-scaffold
  and its confirmation gate come first.

## Rules
- Scope-check before refining: if the seed is several subsystems, decompose into separate lines first.
- One question per turn. Never batch questions into a wall.
- Apply YAGNI — strip speculative features; bias toward the smallest useful prototype.
- Propose 2-3 approaches with a recommendation for consequential decisions; let the developer choose.
- Validate the design in chunks, with depth proportional to the line's shape (light for throwaway,
  sectioned for deploys/aws-dev).
- Never draft the spec before target and shape are resolved.
- Never ratify on the developer's behalf — ratification is theirs.
- The "Done means" block must be verifiable, because it becomes the loop's stopping condition.
