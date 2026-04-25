#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

bash ./check-morphe-update.sh
status=$?

if [ "$status" -eq 2 ]; then
    bash ./main.sh
fi
