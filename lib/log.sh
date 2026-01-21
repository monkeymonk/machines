#!/usr/bin/env bash
set -euo pipefail

# Base logging helpers with optional verbosity control.
LOG_LEVEL=${LOG_LEVEL:-info}
LOG_LEVEL_ORDER=(debug info warn error)

log_level_index() {
  local level=$1
  for i in "${!LOG_LEVEL_ORDER[@]}"; do
    [[ "${LOG_LEVEL_ORDER[i]}" == "$level" ]] && echo "$i" && return 0
  done
  echo "0"
}

log_should_emit() {
  local target=$1
  [[ $(log_level_index "$LOG_LEVEL") -le $(log_level_index "$target") ]]
}

log_debug() {
  [[ $(log_level_index "$LOG_LEVEL") -le $(log_level_index "debug") ]] || return 0
  printf "\033[34mDEBUG\033[0m %s\n" "$*"
}

log_info() {
  printf "\033[32mINFO\033[0m  %s\n" "$*"
}

log_warn() {
  printf "\033[33mWARN\033[0m  %s\n" "$*" >&2
}

log_error() {
  printf "\033[31mERROR\033[0m %s\n" "$*" >&2
}
