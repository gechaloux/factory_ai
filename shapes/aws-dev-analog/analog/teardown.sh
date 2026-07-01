#!/usr/bin/env bash
# teardown.sh — destroy the dev stack and verify nothing was orphaned.
# For aws-dev-analog the teardown check is part of "done" — a real account accrues cost and drift,
# so orphaned resources are a real (non-prod) disruption.
set -euo pipefail
cd "$(dirname "$0")/.."   # line root

: "${AWS_DEV_ROLE_ARN:?set AWS_DEV_ROLE_ARN}"

echo "[aws-dev] assuming dev role for teardown..."
CREDS=$(aws sts assume-role --role-arn "$AWS_DEV_ROLE_ARN" --role-session-name "line-teardown" --output json)
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['AccessKeyId'])")
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['SecretAccessKey'])")
export AWS_SESSION_TOKEN=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['SessionToken'])")

export TF_VAR_analog=false
export TF_VAR_stage=dev

echo "[aws-dev] terraform destroy on dev account..."
terraform destroy -auto-approve -input=false

# Orphan check: terraform state should be empty after destroy.
REMAINING=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
if [ "$REMAINING" != "0" ]; then
  echo "[aws-dev] WARNING: $REMAINING resource(s) remain in state after destroy. Investigate orphans before calling done." >&2
  exit 1
fi
echo "[aws-dev] dev stack destroyed, state clean. no orphans."
