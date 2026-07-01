---
name: add-stack-part
description: >
  Add or amend a part in the factory's technology standard (~/.claude/stack.md). Called by the
  Phase-1 interviewer when a line settles on a technology choice that the standard doesn't yet
  cover, or chooses something against an existing default for a reason worth keeping. Promotes a
  TECHNOLOGY choice (which part) to the standard — never coding conventions, which live in linter
  config. Developer-confirmed, never automatic. This is how the standard accretes from real lines.
---

# add-stack-part — grow the tech standard from real use

The factory's technology standard (~/.claude/stack.md) is not pre-decided. It accretes: a part used
in one line stays line-local until it earns a place in the standard. This skill is that promotion
path for technology choices, the radar-amendment half of the compounding rule applied to the stack.

It is called BY the Phase-1 interviewer, not directly by the developer mid-build. The interviewer
invokes it when, during a line interview, the line lands on a technology that the standard is silent
on, or deviates from a default for a reason that will recur.

## When the interviewer should call this
- The standard has a layer marked `unset` and this line just decided it (e.g. no default datastore
  yet, this line picked Postgres for reasons that generalize).
- The line chose against an existing default and the REASON is reusable (e.g. default is FastAPI but
  this line needs Node for websocket-heavy realtime — that's a deviation rule worth recording, not a
  one-off).
- A whole new layer appears that the standard never named (e.g. first line to need a queue).

## When NOT to call it
- A one-off choice unlikely to recur → leave it in the line, do not amend the standard.
- A coding convention (formatting, naming, project layout, error-handling style) → that is NOT a
  stack part. It belongs in the line's lint/format config enforced by code-ci, never in stack.md.
  If the interviewer is tempted to record a "how to write it" rule here, stop — wrong artifact.
- Anything domain-specific to the line's subject → never graduates.

## What a stack part is
A technology decision at a layer, with a default and a deviation rule:
  layer:        backend | frontend | persistence | queue | iac | test | lint | <new>
  default:      the part the factory reaches for at this layer
  version:      pinned version / range, if relevant
  deviate when: the one-line rule for when a line should pick something else
  notes:        conventions/wiring that travel with the part (NOT coding style — setup, not style)

## Steps
1. Read ~/.claude/stack.md (create it if absent, with a header and empty layers).
2. Determine: is this a NEW layer, a NEW default for an unset layer, or a DEVIATION RULE on an
   existing default? Frame the amendment accordingly — adding a default vs. extending a deviation rule
   are different edits.
3. Generalize: strip the line's fingerprints. The amendment must read as a factory-level rule, not
   "perf-tool used Postgres." If it can't be generalized, it's a line-local choice — don't amend.
4. SHOW the developer the exact proposed amendment to stack.md and WAIT. This is a confirmation gate,
   same as /promote — the developer owns the standard, the skill executes the change.
5. On confirmation, write the amendment to ~/.claude/stack.md. Prefer extending an existing entry
   (e.g. adding a deviation clause) over adding a near-duplicate layer.
6. Log it to ~/.claude/factory-log.jsonl (kind: stack-amendment, layer, change, from-line).
7. Return to the interview. The amended standard is now in effect for THIS line and all future ones.

## Rules
- Technology choices only. Coding conventions go to the linter, never here.
- Developer-confirmed. Never amend the standard silently.
- Generalize before writing; refine an existing entry rather than duplicating.
- Don't inflate the standard with one-offs — amend only when the choice or its deviation rule will recur.
