#!/usr/bin/env bash
set -euo pipefail

HAS_CHANGE=0
STAMP_FILE=".patch-state"

(
    cd apks-patched &&
        (
            APKS_DIR="../apks"
            PATCHES="../patches.mpp"
            CLI_JAR="../morphe-cli.jar"
            CURRENT_STAMP="$(
                sha256sum "$CLI_JAR" "$PATCHES" |
                    awk '{print $1}' |
                    tr '\n' ' ' |
                    sed 's/ $//'
            )"
            PREVIOUS_STAMP=""

            if [ -f "$STAMP_FILE" ]; then
                PREVIOUS_STAMP="$(cat "$STAMP_FILE")"
            fi

            if [ "$CURRENT_STAMP" != "$PREVIOUS_STAMP" ]; then
                echo "Patch inputs changed -> repatch all APKs"
                rm -f ./*-patched.apk
            fi

            for apk in "$APKS_DIR"/*.apk; do
                [ -e "$apk" ] || continue

                base=$(basename "$apk")
                patched="${base%.apk}-patched.apk"

                echo ""
                echo "Checking: $base"

                if [ -f "$patched" ]; then
                    echo "Skip (already patched): $base"
                    continue
                fi

                echo "Patching: $base"

                if java -jar ../morphe-cli.jar patch "$apk" \
                    --patches="$PATCHES" \
                    --purge \
                    --continue-on-error; then
                    echo "OK: $base"
                    HAS_CHANGE=1
                else
                    echo "FAILED: $base"
                fi
            done

            mv -f *.keystore ../apks-keystore/ 2>/dev/null || true

            if [ "$HAS_CHANGE" -eq 1 ]; then
                printf '%s\n' "$CURRENT_STAMP" >"$STAMP_FILE"
                exit 0
            else
                exit 2
            fi
        )
)
