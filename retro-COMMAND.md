---
name: retro
description: >
  Surface promotion candidates from the current line — reusable mechanisms (patterns, prompts,
  hooks, conventions) that were established or corrected and are NOT domain-specific. Run after a
  line reaches done, or any time the developer wants to capture lessons. This is the read half of
  the compounding rule; /promote is the write half.
---

# /retro — surface what should compound

The factory gets faster only if reusable lessons graduate to the global layer. This command finds
the candidates; it does not promote them (that is /promote, and it is the developer's call).

## What to look for in the current line
Scan the line for things that are reusable MECHANISM, not this line's domain logic:
- Patterns the developer corrected more than once (check evals/regressions/.pending.jsonl and the
  crystallized regression checks — repeated failures often reveal a missing global rule or skill).
- Prompts or approaches that worked notably well and aren't specific to this line's subject
  (e.g. a "summarize a record's history" prompt — reusable; the employee-review wording — not).
- Conventions the developer settled on that contradict or extend the global CLAUDE.md.
- Tooling or harness wiring that was set up by hand and would be wanted again.

## What NOT to surface
- Anything domain-specific to this line. Domain logic stays in the line forever. Only mechanism
  graduates. If a candidate only makes sense for this line's subject, drop it.
- One-offs the developer is unlikely to hit again.

## Output
Present a short list of candidates, each as:
  - what it is (one line)
  - why it's reusable (not domain-bound)
  - proposed promotion target: new skill | global CLAUDE.md rule | new/updated hook
Then stop. The developer chooses which to /promote. Do not promote anything automatically.

## Rule
First time a thing appears in one line = leave it in the line. Surface it as a candidate only if
it's the SECOND time across lines, or it's clearly going to recur. Don't inflate the global layer
with speculative promotions — that is the sprawl this whole discipline exists to prevent.
