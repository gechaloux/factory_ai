#!/usr/bin/env bash
# apply.sh — stand the line's IaC up against the local analog (LocalStack).
# This is the verification environment for a docker-analog line. The SAME Terraform that runs here
# is what /submit later plans against real AWS — no rewrite. Disposable: rerun freely.
set -euo pipefail

cd "$(dirname "$0")/.."   # line root

echo "[analog] bringing up LocalStack..."
docker compose up -d localstack
# wait for the edge port
until curl -sf http://localhost:4566/_localstack/health >/dev/null; do sleep 1; done
echo "[analog] LocalStack ready."

# Terraform is expected to read a local-analog backend/provider config that points at
# http://localhost:4566. Keep the AWS-targeting config and the analog-targeting config as the
# SAME stack with provider endpoints swapped by var — not two different stacks.
export TF_VAR_analog=true

echo "[analog] terraform init + apply against analog..."
terraform init -input=false
terraform apply -auto-approve -input=false

echo "[analog] stack applied to analog. run the line's evals against it now."
