#!/usr/bin/env bash
set -euo pipefail

/opt/mssql/bin/sqlservr &
sqlservr_pid=$!

/usr/local/bin/set-compatibility-level.sh &
compat_pid=$!

cleanup() {
    if kill -0 "${compat_pid}" 2>/dev/null; then
        kill "${compat_pid}" 2>/dev/null || true
        wait "${compat_pid}" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

wait "${sqlservr_pid}"
