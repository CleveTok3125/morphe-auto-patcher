#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

PENDING_VERSION_FILE=".morphe.version.next"
CACHE_FILE=".morphe.version"

set +e
bash ./check-morphe-update.sh
status=$?
set -e

if [ "$status" -eq 1 ]; then
    exit 1
fi

if [ "$status" -eq 2 ]; then
    bash ./main.sh

    if [ -f "$PENDING_VERSION_FILE" ]; then
        mv "$PENDING_VERSION_FILE" "$CACHE_FILE"
    fi
fi
