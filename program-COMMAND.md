---
name: program
description: >
  Start a PROGRAM — app-scale intent that decomposes into multiple connected lines. Use when the
  developer hands intent (often a Claude Design handoff of a whole app) that is clearly more than one
  line, or when the interviewer determines a seed is too big for a single line. Hands to the foreman,
  which establishes the program contract, gets it ratified once, and runs the child lines itself. The
  developer communicates intent at the program level and does not hand-create lines.
---

# /program — realize app-scale intent

Entry point for program-scale work. Three ways it's reached:
- Directly: /program <name> "<intent>"  (for non-handoff app intent)
- From a handoff: import-handoff (the single handoff front door) infers "program" and hands here with
  the inventory already done. The sugar /program <name> --from-handoff <path> "<intent>" funnels
  through import-handoff, so a bundle that's actually one line gets routed to a line instead.
- Indirectly: spec-interview hits "too much for one line" and hands here instead of asking the
  developer to pick a starting point.

## What it does
Hands to the foreman skill, which:
1. Establishes the program contract (shared model, stack, design system, child lines, seams, graph).
2. Presents it for the developer to ratify — ONCE. This is the only program-level human gate up front.
3. On ratification, decomposes into the dependency graph and runs the lines serially in order by
   spawning a SUBAGENT per child (the foreman's delegate) that executes new-line autonomously, holding
   the seams, integrating at the end. After ratification the foreman runs hands-off — no developer
   questions except a contract change order or a PR approval.

Handoffs do not enter here directly. Any bundle goes through import-handoff first — the single handoff
front door — which extracts, inventories, and INFERS the tier. When it infers a program, it hands here
WITH the inventory already done: the app-wide design tokens become the program contract's design system
and the implied entities seed its shared data model, established once, before decomposition. The
/program --from-handoff <path> form is sugar that funnels through import-handoff (so a bundle that's
actually one line is routed to a line instead). The foreman owns where the frontend lives across the
child lines.

## What the developer does and doesn't do
- DOES: communicate the top-level intent; ratify the program contract once; review PRs for deploying
  lines; approve any program-contract change order.
- DOES NOT: create the individual lines, sequence them, or thread shared context between them. That
  is the foreman's job — that's the point.

## Rule
Never make the developer hand-create or sequence the child lines. If you're about to ask "which line
first?", stop — derive it from the dependency graph instead.
