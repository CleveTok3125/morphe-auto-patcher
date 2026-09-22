#!/usr/bin/env bash
set -uo pipefail

MANUAL_FILE="manual-downloads.txt"
LIST="downloaded.list"
APKS_DIR="apks"

map_pkg() {
    case "$1" in
    com.google.android.youtube)
        echo "google-inc youtube bundle arm64-v8a"
        ;;
    com.google.android.apps.youtube.music)
        echo "google-inc youtube-music bundle arm64-v8a"
        ;;
    com.reddit.frontpage)
        echo "redditinc reddit bundle"
        ;;
    *)
        return 1
        ;;
    esac
}

: >"$MANUAL_FILE"
touch "$LIST"
mkdir -p "$APKS_DIR"

declare -a VERSION_LINES=()
mapfile -t VERSION_LINES < <(
    java -jar morphe-cli.jar list-versions --patches=patches.mpp 2>/dev/null |
        awk '
        /Package name:/ { pkg=$NF; next }
        /^[[:space:]]+[0-9]/ { if (pkg != "") print pkg, $1 }
        '
)

declare -A TARGET=()
for line in "${VERSION_LINES[@]:-}"; do
    [ -z "$line" ] && continue
    pkg="${line%% *}"
    ver="${line##* }"
    map_pkg "$pkg" >/dev/null 2>&1 || continue
    [ -n "${TARGET[$pkg]:-}" ] && continue
    TARGET[$pkg]="$ver"
done

if [ "${#TARGET[@]}" -eq 0 ]; then
    echo "No managed packages found in patches"
    exit 0
fi

for pkg in "${!TARGET[@]}"; do
    target="${TARGET[$pkg]}"
    shopt -s nullglob
    for file in "$APKS_DIR/${pkg}"_*; do
        fname="$(basename "$file")"
        case "$fname" in
        "${pkg}_${target}"*) ;;
        *)
            echo "Prune unsupported: $fname (target ${target})"
            rm -f "$file"
            rest="${fname#"${pkg}"_}"
            have="${rest%%-*}"
            sed -i "\|^${pkg} ${have} |d" "$LIST"
            ;;
        esac
    done
    shopt -u nullglob
done

for pkg in "${!TARGET[@]}"; do
    target="${TARGET[$pkg]}"
    mapped="$(map_pkg "$pkg")" || continue
    read -r org repo dltype dlarch <<<"$mapped"
    dltype="${dltype:-apk}"
    dlarch="${dlarch:-*}"
    page_url="https://www.apkmirror.com/apk/${org}/${repo}/${repo}-${target//./-}-release/"

    local_file="$(find "$APKS_DIR" -maxdepth 1 -type f \
        \( -name "${pkg}_${target}*.apk" -o -name "${pkg}_${target}*.apkm" \) 2>/dev/null | head -n1)"

    if [ -n "$local_file" ]; then
        echo "Using local APK: $(basename "$local_file")"
        if ! grep -q "^${pkg} ${target} done$" "$LIST" 2>/dev/null; then
            echo "${pkg} ${target} done" >>"$LIST"
        fi
        continue
    fi

    echo ""
    echo "Downloading ${pkg} (${target}) -> ${org}/${repo}"

    status=0
    (
        cd "$APKS_DIR" || exit 1

        DL_ARCH="$dlarch"
        DL_DPI="nodpi"
        [ "$dltype" = "bundle" ] && DL_DPI="*"

        FILE_NAME=$(bun ../apkmirror-downloader/src/cli.ts download "$org" "$repo" \
            --version "$target" \
            --arch "$DL_ARCH" \
            --fallbackarch armeabi-v7a \
            --dpi "$DL_DPI" \
            --type "$dltype" 2>&1 |
            grep -oE "Downloaded to .*" |
            sed 's/Downloaded to //')

        if [ -z "$FILE_NAME" ]; then
            echo "FAILED (no output path): ${pkg} ${target}"
            exit 1
        fi

        if [ ! -s "$FILE_NAME" ]; then
            echo "FAILED (empty file): $FILE_NAME"
            rm -f "$FILE_NAME"
            exit 1
        fi

        if ! file "$FILE_NAME" | grep -qi "android\|zip"; then
            echo "FAILED (invalid apk): $FILE_NAME"
            rm -f "$FILE_NAME"
            exit 1
        fi

        echo "${pkg} ${target} done" >>../downloaded.list
        echo "OK: ${pkg} ${target}"
    ) || status=$?

    if [ "$status" -ne 0 ]; then
        echo "MANUAL DOWNLOAD REQUIRED: ${pkg} ${target} (${dltype}, arch=${dlarch})"
        {
            echo "# ${pkg} ${target} (${dltype}, arch=${dlarch})"
            echo "# save the file into ${APKS_DIR}/ with prefix ${pkg}_${target}"
            echo "$page_url"
        } >>"$MANUAL_FILE"
    fi
done

exit 0
