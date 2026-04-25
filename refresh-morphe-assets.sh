#!/usr/bin/env bash
set -e

fetch_latest() {
    local REPO="$1"
    local PATTERN="$2"
    local OUTPUT="$3"
    local META_FILE="$4"

    echo "Checking $OUTPUT"

    JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

    URL=$(echo "$JSON" | jq -r \
        --arg pattern "$PATTERN" \
        '.assets[] | select(.name | test($pattern)) | .browser_download_url' |
        head -n1)

    if [[ -z "$URL" || "$URL" == "null" ]]; then
        echo "File not found for $REPO"
        return
    fi

    echo "URL: $URL"

    NEW_META=$(curl -sIL "$URL" | grep -i last-modified | cut -d' ' -f2- | tr -d '\r')

    if [[ -f "$OUTPUT" && -f "$META_FILE" ]]; then
        OLD_META=$(cat "$META_FILE")

        if [[ "$OLD_META" == "$NEW_META" ]]; then
            echo "Not modified → skip"
            return
        else
            echo "New version detected"
        fi
    fi

    echo "Downloading..."
    curl -L "$URL" -o "$OUTPUT"

    echo "$NEW_META" >"$META_FILE"

    echo "Done $OUTPUT"
    echo ""
}

# morphe-cli
fetch_latest \
    "MorpheApp/morphe-cli" \
    "\.jar$" \
    "morphe-cli.jar" \
    ".morphe.cli.meta"

# morphe-patches
fetch_latest \
    "MorpheApp/morphe-patches" \
    "^patches-.*\.mpp$" \
    "patches.mpp" \
    ".morphe.patches.meta"
