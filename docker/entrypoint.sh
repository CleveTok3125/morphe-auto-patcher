#!/bin/sh
set -eu

SRC_DIR="/app/public"
DST_DIR="/srv/public"
LATEST_NAME=""

rm -rf "${DST_DIR}"
mkdir -p "${DST_DIR}"

if [ -d "${SRC_DIR}" ]; then
    cp -a "${SRC_DIR}/." "${DST_DIR}/" 2>/dev/null || true

    for dir in "${SRC_DIR}"/*; do
        [ -d "${dir}" ] || continue

        base_name="$(basename "${dir}")"
        [ "${base_name}" = "latest" ] && continue

        if [ -z "${LATEST_NAME}" ] || [ "${base_name}" \> "${LATEST_NAME}" ]; then
            LATEST_NAME="${base_name}"
        fi
    done
fi

if [ -n "${LATEST_NAME}" ]; then
    ln -sfn "${LATEST_NAME}" "${DST_DIR}/latest"
fi

exec nginx -g "daemon off;"
