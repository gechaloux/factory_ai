# Shape: docker-analog

The default line shape. Verification runs against a disposable Docker + LocalStack stand-in for
AWS. Cheap, fenced, fast, fully disposable — so disruption stays LOW and the loop runs wide open.
The IaC artifact applies to this local analog AND is what /submit sends to the PR; same artifact
both sides.

new-line copies this template into a line when the interview confirms shape: docker-analog.
Tailor the mocked services to the line's `services` field — don't run services the line doesn't use.

## What gets copied into the line
- docker-compose.yml   — LocalStack + any datastore/containers the line needs
- analog/apply.sh      — applies the line's IaC against LocalStack (the verification environment)
- analog/teardown.sh   — disposes the analog (docker compose down -v); fail-loud-and-cheap reset
- analog/README.md     — this file, trimmed to the line's services

## How it serves the loop
The shape is the loop's execution environment (its sandbox); the deterministic loop itself is the
loop-gate Stop/SubagentStop hook running the line's eval suite (evals/run.sh). The shape just stands
the sandbox up.
1. The line authors IaC (Terraform pointed at the LocalStack endpoint for local apply).
2. analog/apply.sh stands the stack up in the analog (once, at build start).
3. The eval suite (raised tests + evals) runs against the standing local stack — invoked by the
   loop-gate every time the agent tries to finish, not by anyone's judgment.
4. Red suite → the loop-gate routes the failures back and the agent iterates; burn-detect ratchets
   repeats into regressions. Green suite → the gate marks the line local-done.
5. Local "done" = the eval suite is green (applies clean to the analog + behaves per "Done means").
6. /submit re-plans the SAME IaC against real AWS and opens the PR.

## When this shape is the WRONG choice
If the line depends on something LocalStack can't faithfully represent — IAM assume-role chains,
real cross-account access, real networking/VPC semantics, managed-service behavior, or scale —
the analog lies, and a passing local check is not trustworthy. Those lines use the aws-dev-analog
shape instead. The interview is where this gets caught.
