# Program scaffold (reference)

A program lives at ~/prototypes/<program-name>/ and contains its child lines as subdirectories.
The foreman creates and owns these files. This is a reference for their shape; the foreman writes
the real ones from the ratified program contract.

## ~/prototypes/<program>/PROGRAM.md  (the human-ratified program contract)
```
# <program> — program intent
<one-paragraph statement of what the whole system does>

## Shared data model
<the entities the whole program uses — established once, inherited by every line>

## Stack
<read once from ~/.claude/stack.md for the whole program; deviations noted>

## Design system
<if seeded from a handoff: the app-wide design tokens, established once, inherited by every line>

## Lines
- <line-a>: <its slice of intent>
- <line-b>: <its slice of intent>
- ...

## Seams (frozen interface contracts between lines)
- <line-a> EXPOSES <interface> ; <line-b> CONSUMES it
- ...

## Build order (dependency graph)
- layer 0 (foundation): <lines with no dependencies — shared model, shared APIs>
- layer 1: <lines depending only on layer 0>
- ...
(Stage 1 runs these serially in this order. Stage 2 runs same-layer lines with no seam in parallel.)

## Deviation tolerance
<high | low | zero> — how much a line's build may diverge from the program contract before escalating.
```

## ~/prototypes/<program>/.program  (machine-readable state)
```
name: <program>
status: <decomposing | ratified | building | integrating | done>
seeded_from: <handoff path | one-liner>
lines:
  - name: <line-a>
    slice: "<intent slice>"
    layer: 0
    exposes: [<interface>, ...]
    consumes: [<interface>, ...]
    status: <pending | building | done>
  - name: <line-b>
    layer: 1
    exposes: [...]
    consumes: [<line-a interface>]
    status: pending
seams:
  - from: <line-a>
    interface: <interface id>
    to: [<line-b>, ...]
    frozen: true
graph:               # adjacency: line -> the lines it depends on
  <line-a>: []
  <line-b>: [<line-a>]
created: <timestamp>
```

## ~/prototypes/<program>/PROGRAM_CONTEXT.md  (shared cross-line memory)
```
# <program> — program memory
Cross-cutting decisions made while building one line that the others should know. Written by the
foreman and inheritable by child lines. Each line still keeps its own CONTEXT.md for line-local memory.
```

## Child lines
Each child line is a normal line directory under the program:
  ~/prototypes/<program>/<line-a>/   (CLAUDE.md, CONTEXT.md, SPEC.md, .factory, src/, evals/)
The child's CLAUDE.md notes it is a child of <program> and inherits the program contract; its SPEC.md
is a DELTA (its slice + the seams it must honor), not a from-scratch contract.
