#!/usr/bin/env bash
set -euo pipefail

HAS_CHANGE=0
STAMP_FILE=".patch-state"

required_patch_for() {
    case "$1" in
    com.google.android.youtube | com.google.android.apps.youtube.music)
        echo "GmsCore support"
        ;;
    *)
        echo ""
        ;;
    esac
}

validate_result() {
    local result_file="$1"
    local required_patch="$2"

    [ -f "$result_file" ] || return 1
    command -v jq >/dev/null 2>&1 || return 1

    jq -e '
        ((.patchingSteps // []) | map(select(.success == false)) | length) == 0
        and ((.failedPatches // []) | length) == 0
        and ((.appliedPatches // []) | length) > 0
    ' "$result_file" >/dev/null 2>&1 || return 1

    if [ -n "$required_patch" ]; then
        jq -e --arg n "$required_patch" \
            '(.appliedPatches // []) | any(.name == $n)' \
            "$result_file" >/dev/null 2>&1 || return 1
    fi

    return 0
}

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

            rm -rf "$APKS_DIR"/tmp_*
            rm -rf ../morphe-data/tmp
            mkdir -p ../apks-keystore

            for p in ./*-patched.apk; do
                [ -e "$p" ] || continue
                stem="${p#./}"
                stem="${stem%-patched.apk}"
                if [ ! -e "$APKS_DIR/${stem}.apk" ] && [ ! -e "$APKS_DIR/${stem}.apkm" ]; then
                    echo "Remove orphan patched: $p"
                    rm -f "$p"
                fi
            done

            WORK_DIR="$(mktemp -d)"
            trap 'rm -rf "$WORK_DIR"' EXIT
            RESULT_FILE="$WORK_DIR/result.json"
            LOG_FILE="$WORK_DIR/run.log"

            for apk in "$APKS_DIR"/*.apk "$APKS_DIR"/*.apkm; do
                [ -e "$apk" ] || continue

                base=$(basename "$apk")
                base_noext="${base%.*}"
                patched="${base_noext}-patched.apk"
                pkg="${base_noext%%_*}"

                echo ""
                echo "Checking: $base"

                if [ -f "$patched" ]; then
                    echo "Skip (already patched): $base"
                    continue
                fi

                echo "Patching: $base"

                rm -f "$RESULT_FILE" "$LOG_FILE"
                keystore="../apks-keystore/${patched%.apk}.keystore"
                ok=0
                if java -jar ../morphe-cli.jar patch "$apk" \
                    --patches="$PATCHES" \
                    --out="$patched" \
                    --keystore="$keystore" \
                    -e "GmsCore support" \
                    -r "$RESULT_FILE" \
                    --continue-on-error >"$LOG_FILE" 2>&1; then
                    ok=1
                fi

                required_patch="$(required_patch_for "$pkg")"
                valid=0
                if [ "$ok" -eq 1 ]; then
                    if [ -f "$RESULT_FILE" ] && command -v jq >/dev/null 2>&1; then
                        if validate_result "$RESULT_FILE" "$required_patch"; then
                            valid=1
                        fi
                    elif ! grep -q "Applying 0 patches" "$LOG_FILE" 2>/dev/null; then
                        valid=1
                    fi
                fi

                if [ "$valid" -eq 1 ]; then
                    echo "OK: $base"
                    HAS_CHANGE=1
                else
                    echo "FAILED: $base (patch did not apply)"
                    rm -f "$patched"
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
