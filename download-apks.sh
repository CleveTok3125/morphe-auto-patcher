#!/usr/bin/env bash

map_pkg() {
    case "$1" in
    com.google.android.youtube)
        echo "google-inc youtube"
        ;;
    com.google.android.apps.youtube.music)
        echo "google-inc youtube-music"
        ;;
    *)
        return 1
        ;;
    esac
}

BLACKLIST="com.reddit.frontpage"
touch downloaded.list

java -jar morphe-cli.jar list-versions patches.mpp |
    awk -v bl="$BLACKLIST" '
BEGIN {
  split(bl, b, " ")
  for (i in b) blacklist[b[i]] = 1
}
/Package name:/ {
  pkg=$NF
  next
}
/^[[:space:]]+[0-9]/ {
  if (!(pkg in blacklist) && !seen[pkg]++) {
    print pkg, $1
  }
}
' |
    awk '!seen[$1]++' |
    while read pkg ver; do
        echo ""
        mapped=$(map_pkg "$pkg") || continue
        read org repo <<<"$mapped"

        if grep -q "^$pkg $ver done$" downloaded.list 2>/dev/null; then
            echo "Skip: $pkg $ver"
            continue
        fi

        echo "Downloading $pkg ($ver) -> $org/$repo"

        (
            cd apks || exit 1

            FILE_NAME=$(bun ../apkmirror-downloader/src/cli.ts download "$org" "$repo" \
                --version "$ver" \
                --arch arm64-v8a \
                --fallbackarch armeabi-v7a \
                --dpi nodpi \
                --type apk |
                grep -oE "Downloaded to .*" |
                sed 's/Downloaded to //')

            if [ -z "$FILE_NAME" ]; then
                echo "FAILED (no output path): $pkg $ver"
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

            echo "$pkg $ver done" >>../downloaded.list

            echo "OK: $pkg $ver"
        )

        if [ $? -ne 0 ]; then
            echo "$pkg $ver failed"
            # echo "$pkg $ver failed" >>downloaded.list
            continue
        fi

    done
