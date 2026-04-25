#!/usr/bin/env bash

bash ./check-morphe-update.sh
status=$?

if [ "$status" -eq 2 ]; then
    bash ./main.sh
fi
