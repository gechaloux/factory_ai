---
name: import-handoff
description: >
  Crack open a Claude Design handoff bundle (.tar.gz/.zip) and route it into the factory. This is the
  SINGLE front door for any handoff: it extracts and inventories the bundle, INFERS whether the design
  is one line or a whole program, and hands to the right owner (new-line for a single feature, foreman
  for an app). The developer does not pre-declare line vs program — the bundle's contents decide. The
  frontend is a strong seed for the WHAT, never settled architecture; it enters verification like any
  other code.
---

# import-handoff — the handoff front door (infers line vs program)

A Claude Design handoff bundle is not a screenshot. It carries the component structure as a
machine-readable spec, the design tokens used on the canvas, the layout hierarchy, the referenced
assets, and the design decisions documented during the design conversation. That makes it a rich SEED
— but it is a prototype frontend: strong on "what screens exist / what it looks like", silent on
target, shape, backend, data model, and what "done" means.

This skill owns ONE job that nothing else does: turn a bundle into the right kind of work. It does not
assume a tier. A single feature becomes a line; a whole app becomes a program. The developer hands a
bundle + a one-liner of intent and does NOT say which — the inventory decides.

## Entry
- Direct: `/import-handoff <path> "<intent>"` — the canonical entry for any bundle.
- Via sugar: `/new-line <name> --from-handoff <path> "<intent>"` and
  `/program <name> --from-handoff <path> "<intent>"` both funnel here FIRST. The flag is a hint, not a
  commitment — if the inventory disagrees with the implied tier, this skill routes to the correct one
  and says so. (So `new-line --from-handoff` on a whole app is redirected to a program, not forced
  into one line; `program --from-handoff` on a single feature is redirected to a line.)

## Critical posture
The default output of a design tool is prototype-grade, not production-grade — it can look ready when
it is not. Treat the frontend as the most concrete part of the seed, NOT as settled architecture and
NOT as exempt from verification. It goes through the loop, the weight-vector checks, and the as-built
conformance check like any other code.

## Steps

1. Locate and safely extract the bundle (.tar.gz/.zip) into a NEUTRAL staging dir — not inside a line
   or a program yet, because the tier isn't decided. Use `~/prototypes/.handoff-staging/<name>/`. Guard
   against path traversal (reject archive entries with absolute paths or `..`). If extraction fails or
   it doesn't look like a Claude Design handoff, stop and tell the developer rather than guessing.

2. Inventory what's inside, tier-agnostically:
   - the component/structure spec (screens + component tree)
   - design tokens (colors, spacing, typography actually used)
   - layout hierarchy
   - referenced assets (images, icons, fonts)
   - any manifest/README and design-decision notes from the design chat
   Produce a structured summary: what screens exist, what components, what the tokens are, and — most
   load-bearing for what follows — the data ENTITIES and user FLOWS the frontend implies (a form with
   these fields implies this model; a list+detail pair implies this resource).

2b. DERIVE THE HANDOFF ACCEPTANCE SUITE — the verification artifact nothing else produces. The
   handoff is the vision in frozen form; distilling it into a contract is lossy, and once distilled it
   is normally discarded from the loop, so a faithful build of a contract that silently dropped a screen
   or flow passes green forever. To close that, turn the inventory into a CHECKABLE acceptance suite
   while the bundle is open: every screen present, every documented user flow reachable, key behaviors
   and copy and tokens matching. This is crystallized criteria fed through the harness like any other
   eval — NOT a critic that whispers subjective notes at done. Visual/UX fidelity is judge-backed
   (rendered-vs-design); structural presence (screens, flows, fields) is deterministic where it can be.
   RETAIN the original bundle + inventory as a durable verification artifact (it is no longer
   throwaway); the owner places it (line `evals/handoff-acceptance/`, or the program contract). The
   acceptance check is governed by the PRESENT-OR-ACCOUNTED-FOR rule, not pixel-match: a handoff
   element is satisfied if it is present in the build OR explicitly accounted for by a recorded
   contract decision — because the frontend is a seed, not settled architecture, deliberate divergence
   is allowed, silent loss is not. (How it routes at done lives in as-built / the foreman integration
   check.)

3. INFER the tier from the inventory, and SHOW the reasoning. This is a routing decision, surfaced but
   NOT a human gate — do not stop and ask for approval; the next gate (ratification of the line spec or
   the program contract) validates the call either way.
   - LINE when the bundle is genuinely one screen/feature, or a few screens of a SINGLE subsystem with
     one coherent data slice and no internal seams.
   - PROGRAM when the bundle spans multiple subsystems — multiple resource families, distinct areas
     (e.g. an admin area + a customer area), or screens whose implied entities/flows clearly cut across
     more than one backend/data boundary. A full Claude Design export of an app is the common case.
     When torn between a fat line and a thin program, prefer the PROGRAM — a program can hold a single
     line, but a line can't later be split without rework.
   State the inferred tier and the one or two signals that decided it. If the developer's command
   implied the other tier, say you're overriding it and why. The developer may correct the call;
   otherwise proceed.

4. Route — hand the staged bundle + the inventory to the owner. The OWNER does the final placement;
   this skill never drops a frontend into a tier it didn't choose:
   - LINE → hand to new-line: it scaffolds the line, moves the staged frontend into the line's
     `src/frontend/` (tokens kept as the line's styling source of truth), places the retained bundle +
     acceptance suite under the line's `evals/handoff-acceptance/` (so build-vs-handoff is part of the
     suite, not lost), seeds the line `CONTEXT.md` with the design rationale (decisions already made;
     parts that are prototype-grade and need hardening), then hands to spec-interview to interview the
     GAPS (backend, persistence, target, shape, full "Done means").
   - PROGRAM → hand to the foreman: the app-wide design tokens become the program contract's design
     system and the implied entities seed its shared data model, established ONCE. The foreman
     decomposes into child lines and owns where the frontend lives across them (typically a client/web
     line consuming the API lines per the seams; a frontend that itself splits by subsystem is placed
     into the lines it belongs to). The retained bundle + acceptance suite become part of the program
     contract (the foreman owns build-vs-handoff at the program integration check, and threads each
     line's slice of the suite into its subcontract). Seed `PROGRAM_CONTEXT.md` with the cross-cutting
     design rationale.
   Clean up the staging dir once the owner has taken its contents.

## What this does NOT do
- It does not skip the interview/contract. The frontend seeds the WHAT; target/shape/backend/done are
  still interviewed and ratified (line) or established in the program contract and ratified (program).
- It does not treat the frontend as production-ready or as the final architecture.
- It does not exempt the imported code from verification or the as-built conformance check.
- It does not, itself, scaffold a line or a program — it routes to the owner that does.

## Rules
- One front door: any handoff enters here and the inventory picks the tier. `--from-handoff` on
  new-line/program is a hint that funnels here, never a binding choice.
- Inspect before placing; stage neutrally; guard against malicious archive paths.
- Inferring the tier is autonomous (surfaced, not gated) — do NOT add a human gate; ratification is
  the gate.
- The frontend is a seed, not a settled answer — interview the gaps, verify the code.
- Carry the design rationale into the right memory (line `CONTEXT.md` or program `PROGRAM_CONTEXT.md`)
  so the loop doesn't re-decide what the design already decided.
- The design tokens are the styling source of truth — don't let the build reinvent them.
- The handoff is a RETAINED verification artifact, not throwaway. Derive the acceptance suite while the
  bundle is open and carry it to the owner (line `evals/handoff-acceptance/` or the program contract),
  so build-vs-handoff can be checked at done. The handoff is the only ground truth for whether the
  contract distilled the vision faithfully — discard it and that check becomes impossible.
- The acceptance suite is crystallized criteria fed through the harness, never a subjective critic in
  the loop. Present-or-accounted-for, not pixel-match: deliberate divergence recorded in the contract
  is fine; an unaccounted-for missing screen/flow is the lossy-distillation catch.
