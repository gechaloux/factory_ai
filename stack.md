# Factory technology standard

The parts the factory reaches for. This is the TECHNOLOGY standard (which parts) — not coding
conventions (how to write them), which live in each line's lint/format config enforced by code-ci.

It is not pre-decided. Layers start `unset`. They fill in as real lines procure parts, via the
add-stack-part skill (called by the Phase-1 interviewer, developer-confirmed). A part used once
stays line-local; it graduates here only when it — or its deviation rule — will recur.

How the line interviewer uses this file:
- For any layer with a default, the interview ASSUMES it and does NOT ask. (Kills the recurring
  "which stack" question.)
- It asks only where a layer is `unset`, or where the line's needs trip a `deviate when` rule.
- When a line decides an unset layer or deviates for a reusable reason, the interviewer calls
  add-stack-part to amend this file.

## Layers

### backend
default:      unset
version:      —
deviate when: —
notes:        —

### frontend
default:      unset
version:      —
deviate when: —
notes:        —

### persistence
default:      unset
version:      —
deviate when: —
notes:        —

### iac
default:      Terraform
version:      —
deviate when: (factory invariant — deploying lines emit IaC; this is the default tool)
notes:        same artifact validates against the analog and submits to the PR

### test
default:      unset
version:      —
deviate when: —
notes:        runner that code-ci executes against the line's tests + evals/

### lint
default:      unset
version:      —
deviate when: —
notes:        this is the ENFORCEMENT point for coding standards — the linter is the source of
              truth, not prose. code-ci runs it as a required merge gate.

<!-- new layers (queue, cache, auth, etc.) get added here by add-stack-part as lines need them -->
