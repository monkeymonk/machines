#!/usr/bin/env bash
set -euo pipefail

# Dev-role tooling. Most CLI essentials live in core.sh / cli.sh; this is the
# slot for extras a dev workstation/server wants beyond the baseline.
DEV_PACKAGES=()

install_dev_packages() {
  if (( ${#DEV_PACKAGES[@]} == 0 )); then
    log_debug "no extra dev packages"
    return 0
  fi
  install_packages "${DEV_PACKAGES[@]}"
}
