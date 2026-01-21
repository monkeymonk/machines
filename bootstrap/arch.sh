#!/usr/bin/env bash
set -euo pipefail

# Arch-specific tweaks that run before package installs.
bootstrap_arch() {
  local dry_run="${DRY_RUN:-false}"

  log_info "Running Arch bootstrap hooks"

  if [[ "$dry_run" == true ]]; then
    log_info "Would run pacman -Syu (dry-run)"
    return 0
  fi

  sudo pacman -Syu --noconfirm
}
