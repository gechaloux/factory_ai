# Shape: aws-dev-analog

The higher-fidelity line shape. Verification runs against a REAL non-prod AWS account (dev), not a
local mock. Used when a Docker/LocalStack analog can't faithfully represent what the line needs —
IAM assume-role chains, real cross-account access, real networking/VPC semantics, managed-service
behavior, or scale. The interview selects this shape, with reasoning, when fidelity demands it.

Because the analog is real (even if non-prod), disruption is NOT low here. The dev-stage checks are
load-bearing: clean apply, clean teardown, no orphaned resources. eval-scaffold raises disruption
to MED/HIGH for this shape accordingly.

The lifecycle is the same skeleton as docker-analog; only the analog changes:
  local repo → IaC → AWS-dev (apply + eval) → /submit → PR → CI/CD → AWS-prod
Same IaC artifact validated in dev is what crosses the PR to prod.

## What gets copied into the line
- analog/bootstrap.sh   — assumes the dev role, applies the line's IaC to the dev account
- analog/teardown.sh    — destroys the dev stack; verifies no orphaned resources remain
- analog/README.md      — this file, trimmed to the line

## Discipline this shape requires (that docker-analog doesn't)
- Always teardown after verification. A real dev account accrues cost and drift; orphaned resources
  are a real (if non-prod) disruption. The teardown check is part of "done" for this shape.
- The dev account is non-prod but NOT disposable the way a container is. Treat apply/teardown as
  paired operations, never apply-and-walk-away.
- Creds for the dev account come from the line's configured source — never literals (cred-guard enforces).

## When even this is the wrong choice
If the line genuinely cannot be validated outside prod, it does not belong in this factory as an
auto-flowing line. Stop and design it deliberately with the developer — the factory's invariant is
that nothing reaches prod without crossing the PR gate from a validated analog.
