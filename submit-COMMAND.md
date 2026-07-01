---
name: submit
description: >
  Terminal step for a deploying line. Takes the IaC artifact that was validated against the line's
  analog, opens a branch and PR with the plan output in the description, and stops. This is the PR
  gate — the single human-in-the-loop checkpoint before anything reaches a real system. Only for
  lines with target: deploys. local-only lines never invoke this.
---

# /submit — cross the PR gate

The local loop has reached done: the same IaC artifact has applied cleanly against the line's
analog and behaves per the contract's "Done means". /submit packages that validated artifact for
human review and CI/CD. It does not deploy — merging the PR does, via the factory's Actions workflow.

## Preconditions (verify before acting)
- .factory target == deploys. If local-only, refuse — there's nothing to submit.
- status == done (local loop satisfied, raised checks passed against the analog).
- The IaC that will be submitted is the SAME artifact validated against the analog. No cloud rewrite.

## Steps
1. Generate the plan against the real deploy target (terraform plan / cfn change set) — NOT an
   apply. This is the diff the human reviews. Capture its output.
2. Create a branch for the line. Commit the IaC artifact and the line's evals.
3. Open the PR. The description must contain:
   - the contract's "Done means" (what this is meant to do)
   - the plan / change-set output (what it will do to the real world)
   - the line's shape and which checks passed against the analog
   - anything the developer should weigh: blast radius, new resources, anything destructive in the plan
4. Stop. Report the PR link. Do NOT merge — merge is the developer's gate, and CI/CD runs on merge.

## What happens after (not this command's job)
On merge, the factory's GitHub Actions workflow runs: plan → policy/security scan → apply to prod.
Success deploys. That workflow owns real-world disruption safety — which is why the local loop was
allowed to run wide open against a disposable analog.

## Rules
- Plan, never apply, at submit time. The human approves the plan; CI applies it.
- The PR description is the review surface — make the real-world effect legible, especially anything
  destructive or anything that creates new standing resources.
- Never bypass the PR. Nothing reaches prod without crossing it.
