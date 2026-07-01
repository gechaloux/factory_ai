---
name: new-line
description: >
  Instantiate a new factory line (prototype project). Use when the developer wants to start
  a new prototype, build a new tool, or "spin up a line." Takes a short one-liner of intent —
  not a finished spec. Scaffolds the project directory, then hands off to the spec-interview
  skill to produce the ratified contract. Do NOT ask the developer to write a spec up front.
---

# new-line — instantiate a factory line

A line is one prototype. This skill creates its directory and starts it down the lifecycle.
The developer brings a one-liner of intent. They do NOT bring a finished spec — producing the
spec is the job of the interview that follows, not a precondition.

## When invoked
The developer runs something like:
  /new-line <name> "<one-liner of intent>"
e.g. /new-line perf-tool "something to manage employee performance"

Or, to seed from a Claude Design handoff bundle (a prototype frontend exported as .tar.gz/.zip):
  /new-line <name> --from-handoff <path> "<one-liner of intent>"

The name becomes the directory under ~/prototypes/. The one-liner is the seed for the interview.
If --from-handoff is present, do NOT scaffold yet — the bundle might describe a whole app, not one
line. Hand to the import-handoff skill FIRST; it is the single front door for any handoff: it
extracts, inventories, and INFERS whether the design is a line or a program, then routes. The
--from-handoff flag here is only a hint — if import-handoff finds a whole app it routes to a program
instead, and that is correct, not an error. import-handoff calls back into this skill (the line
scaffold below) ONLY when it concludes the bundle is a single line, handing over the staged frontend
to place. With no handoff, run the scaffold below and hand straight to spec-interview as normal.

## Called as a child of a program (autonomous, via a foreman subagent)
new-line is also run BY a foreman subagent — the foreman's delegate — to create a child line of a
program. When invoked that way (the delegate passes the program root + the inherited contract + the
line's slice + the seams it must honor), the child is created UNDER the program directory
(~/prototypes/<program>/<line>/), and its CLAUDE.md notes it is a child of <program> and inherits the
program contract (shared data model, stack, design system). Its SPEC.md is seeded as a DELTA — the
line's slice plus the seams (exposed/consumed interfaces) it must honor.

Critically, the child interview runs in AUTONOMOUS child-of-program mode: it does NOT ask the
developer. The program contract is already ratified, so spec-interview resolves the thin delta from
the inherited contract + the stack standard + YAGNI on its own, making the call a delegate would make.
A gap that cannot be closed without changing a seam or the program contract is returned to the foreman
as a CHANGE ORDER — never raised as a question to the developer. The developer does not ratify child
lines individually; the program contract was already ratified. Pass this mode through to spec-interview.

## Steps

0. GUARD: if --from-handoff was passed directly to new-line, do NOT run the scaffold below yet. Hand to
   import-handoff first (see "When invoked"). You only reach step 1 for a handoff once import-handoff
   has confirmed the bundle is a single line and called back here; for a program it routes to the
   foreman and this skill never runs. With no handoff, proceed to step 1 normally.

1. Create the line directory at ~/prototypes/<name>/ with this structure:
   ~/prototypes/<name>/
   ├── CLAUDE.md        (line-delta stub — see below)
   ├── CONTEXT.md       (line memory stub — see below; read first, written by the loop)
   ├── SPEC.md          (EMPTY — produced by the interview, never pre-filled)
   ├── .factory         (metadata stub — see below)
   ├── src/             (empty)
   └── evals/           (empty — eval-scaffold fills only raised dimensions later)
   Do NOT create a shape harness yet. The shape is not known until the interview confirms it.

2. Write the line CLAUDE.md stub — keep it to the delta from the factory layer:
   ```
   # <name> — line

   ## Read first
   - Read CONTEXT.md before doing anything — it is this line's durable memory (decisions made,
     approaches rejected and why, constraints, the why behind regression checks). It exists to
     stop you re-walking ground earlier runs already covered. Append to it as you work.

   ## What this is
   (set after the interview)

   ## Stack delta from factory defaults
   (only what differs; usually nothing yet)

   ## Hard rules
   - Inherit all factory rules.

   ## Done means
   (set after the interview — this is the contract's success block)
   ```

   Also create an empty CONTEXT.md stub:
   ```
   # <name> — line memory

   Durable memory for this line, written and read BY the loop, not maintained by the developer.
   Records what is NOT recoverable from the code: decisions + rationale, rejected approaches + why,
   constraints/gotchas, and the why behind crystallized regressions. Read first, append as you go.
   eval-scaffold seeds this for persisting lines; it stays minimal for true throwaways.
   ```

3. Write the .factory stub with status=interviewing and everything else unset:
   ```
   name: <name>
   seed: "<one-liner>"
   status: interviewing
   shape: unset        # docker-analog | aws-dev-analog | local-only
   target: unset       # deploys | local-only
   weights: unset      # filled + confirmed by eval-scaffold
   services: unset     # which AWS services the analog must represent (deploying lines)
   eval_cmd: unset     # the suite the loop-gate runs as the stopping condition (set by eval-scaffold)
   loop_max: unset     # iteration cap for the deterministic loop (set by eval-scaffold; default 8)
   routing: default
   created: <timestamp>
   ```

4. Log the line birth to ~/.claude/factory-log.jsonl (one JSON object: name, seed, created).

5. Hand off:
   - If invoked BY import-handoff for a confirmed line: it has already extracted and inventoried the
     bundle. Move the staged frontend into src/frontend/ (tokens kept as the styling source of truth),
     place the retained bundle + acceptance suite under evals/handoff-acceptance/ (so as-built's
     build-vs-handoff check has its ground truth), seed CONTEXT.md with the design rationale
     import-handoff produced, then hand to spec-interview with that starting understanding so it
     interviews the GAPS.
   - Otherwise (no handoff): hand to the spec-interview skill immediately. The interview IS the next
     thing that happens. Pass the seed.
   After handoff, this skill's job is done.

## Rules
- Never pre-fill SPEC.md. An empty spec is correct here.
- Never guess the shape at this stage. It is a confirmed output of the interview.
- If the directory already exists, stop and ask — do not overwrite a line.
- After handoff, this skill's job is done; spec-interview owns the next phase.
