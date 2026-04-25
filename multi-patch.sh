#!/usr/bin/env bash
set -euo pipefail

HAS_CHANGE=0

(
    cd apks-patched &&
        (
            APKS_DIR="../apks"
            PATCHES="../patches.mpp"

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
                exit 0
            else
                exit 2
            fi
        )
)
