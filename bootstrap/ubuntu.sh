#!/usr/bin/env bash
set -euo pipefail

# Ubuntu-specific tweaks that run before package installs.
bootstrap_ubuntu() {
  local dry_run="${DRY_RUN:-false}"

  log_info "Running Ubuntu bootstrap hooks"

  if [[ "$dry_run" == true ]]; then
    log_info "Would run apt-get update (dry-run)"
    return 0
  fi

  sudo apt-get update
}
