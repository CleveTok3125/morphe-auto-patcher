#!/usr/bin/env bash
set -euo pipefail

APK_DIR="apks"
LIST="downloaded.list"

touch "$LIST"

echo -n "Syncing downloaded.list with APK files... "

tmp=$(mktemp)

while read -r pkg ver status; do
    [ -z "${pkg:-}" ] && continue

    if [ "$status" != "done" ]; then
        echo "$pkg $ver $status" >>"$tmp"
        continue
    fi

    apk_file=$(find "$APK_DIR" -type f -name "${pkg}_${ver}*.apk" 2>/dev/null | head -n 1)

    if [ -f "$apk_file" ]; then
        echo "$pkg $ver done" >>"$tmp"
    else
        echo "REMOVE MISSING: $pkg $ver"
    fi

done <"$LIST"

mv "$tmp" "$LIST"

echo "Done."
