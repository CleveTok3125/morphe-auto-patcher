#!/usr/bin/env bash

REPO="MorpheApp/morphe-patches"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
CACHE_FILE=".morphe.version"

response=$(curl -s --fail "$API_URL")
curl_exit=$?

if [ $curl_exit -ne 0 ] || [ -z "$response" ]; then
    echo "ERROR: Cannot fetch release info" >&2
    exit 1
fi

latest_version=$(echo "$response" | grep -m 1 '"tag_name":' | cut -d '"' -f4)

if [ -z "$latest_version" ]; then
    echo "ERROR: Invalid API response" >&2
    exit 1
fi

if [ -f "$CACHE_FILE" ]; then
    local_version=$(cat "$CACHE_FILE")
else
    local_version="none"
fi

if [ "$local_version" != "$latest_version" ]; then
    echo "UPDATE: $local_version -> $latest_version"
    echo "$latest_version" >"$CACHE_FILE"
    exit 2
fi

exit 0
