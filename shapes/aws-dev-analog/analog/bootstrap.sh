#!/usr/bin/env bash
# bootstrap.sh — apply the line's IaC to the real non-prod (dev) AWS account.
# This is the verification environment for an aws-dev-analog line. The analog is REAL, so this is
# paired with teardown.sh — never apply and walk away. The SAME stack validated here is what /submit
# plans against prod.
set -euo pipefail
cd "$(dirname "$0")/.."   # line root

# Dev-account creds come from the line's configured source (env/role assumption). NOT literals.
: "${AWS_DEV_ROLE_ARN:?set AWS_DEV_ROLE_ARN to the dev-account role to assume}"

echo "[aws-dev] assuming dev role..."
CREDS=$(aws sts assume-role --role-arn "$AWS_DEV_ROLE_ARN" --role-session-name "line-analog" --output json)
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['AccessKeyId'])")
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['SecretAccessKey'])")
export AWS_SESSION_TOKEN=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['SessionToken'])")

export TF_VAR_analog=false      # real AWS, dev stage
export TF_VAR_stage=dev

echo "[aws-dev] terraform init + apply to dev account..."
terraform init -input=false
terraform apply -auto-approve -input=false

echo "[aws-dev] stack applied to DEV. run the line's evals against it, then ALWAYS run analog/teardown.sh."
