#!/usr/bin/env bash
set -euo pipefail

log_test_info() {
    echo "[TEST] [$(date +%H:%M:%S)] $*"
}

log_test_error() {
    echo "[ERROR] [$(date +%H:%M:%S)] $*" >&2
}

log_test_pass() {
    echo -e "\033[32m✓ PASS:\033[0m $*"
}

log_test_fail() {
    echo -e "\033[31m✗ FAIL:\033[0m $*"
}

check_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

measure_time() {
    date +%s
}

format_duration() {
    local duration=$(( $2 - $1 ))
    local minutes=$(( duration / 60 ))
    local seconds=$(( duration % 60 ))
    [ $minutes -gt 0 ] && echo "${minutes}m ${seconds}s" || echo "${seconds}s"
}
