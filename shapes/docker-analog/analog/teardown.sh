#!/usr/bin/env bash
# teardown.sh — dispose the analog. Fail-loud-and-cheap reset: there is nothing precious here.
set -euo pipefail
cd "$(dirname "$0")/.."   # line root
echo "[analog] tearing down analog (containers + volumes)..."
docker compose down -v
echo "[analog] gone. rerun analog/apply.sh for a clean stand-up."
