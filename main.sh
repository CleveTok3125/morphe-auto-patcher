#!/usr/bin/env bash
set -euo pipefail

PUBLIC="public"
STAGING="public.new"

cleanup() {
    rm -rf "$STAGING"
}
trap cleanup EXIT

mkdir -p apks apks-patched apks-keystore "$PUBLIC"
rm -rf "$STAGING"
mkdir -p "$STAGING"

bash ./refresh-morphe-assets.sh
bash ./gc-sync.sh
bash ./download-apks.sh

set +e
bash ./multi-patch.sh
code=$?
set -e

if [ "$code" -eq 2 ]; then
    echo ""
    echo "No changes → skip publish"
    exit 0
fi

cp -r apks-patched/. "$STAGING"
rm -f "$STAGING/.patch-state"

ts=$(date +%Y%m%d_%H%M%S)
release="$PUBLIC/$ts"

for apk in "$STAGING"/*.apk; do
    [ -e "$apk" ] || continue
    base="${apk%.apk}"
    case "$base" in *-"$ts") continue;; esac
    mv "$apk" "${base}-${ts}.apk"
done

mv "$STAGING" "$release"
ln -sfn "$ts" "$PUBLIC/latest"

cd "$PUBLIC"
ls -1dt */ | tail -n +4 | xargs -r rm -rf
