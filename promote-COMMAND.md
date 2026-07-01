---
name: promote
description: >
  Graduate a chosen reusable mechanism from the current line to the global factory layer
  (~/.claude). The write half of the compounding rule. Use after /retro surfaces candidates and
  the developer picks one. Promotes mechanism only — never domain logic.
---

# /promote — graduate a lesson to the factory

Takes a candidate (usually one /retro surfaced) and writes it into the global layer so every
future line inherits it from turn one. This is what makes the factory floor faster each run.

## Targets and how to write each
- new skill → create ~/.claude/skills/<name>/SKILL.md. Write the frontmatter description so it
  triggers on the right tasks (the description is what gets matched). Keep the body the procedural
  knowledge, generalized — strip anything specific to the line it came from.
- global CLAUDE.md rule → add a concise line under the appropriate section of ~/.claude/CLAUDE.md.
  Keep the file small and high-signal; if a rule duplicates an existing one, refine the existing
  one instead of adding.
- new/updated hook → add or edit a script in ~/.claude/hooks/ and wire it in ~/.claude/settings.json.

## Generalize before writing
The candidate came out of one line and will carry that line's fingerprints. Before promoting,
rewrite it to be domain-blind: replace line-specific nouns with the general mechanism, drop the
example values, make sure it reads as a factory capability and not a perf-tool (or whatever) detail.
If it can't be generalized without losing its point, it wasn't a promotion candidate — leave it.

## After writing
- Note the promotion in ~/.claude/factory-log.jsonl (kind: promotion, what, target, from-line).
- Confirm to the developer what was promoted and where, in one line.

## Rules
- Mechanism only. Domain logic never graduates.
- Never let the global layer sprawl. Promote when something has earned it (recurred / clearly will),
  not on a hunch. Prefer refining an existing global rule/skill over adding a near-duplicate.
- Promotion is the developer's decision; this command executes it, it does not decide it.
