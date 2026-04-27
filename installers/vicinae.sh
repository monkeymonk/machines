#!/usr/bin/env bash
set -euo pipefail

# vicinae (https://vicinae.com) — Raycast-style launcher.

install_vicinae() {
  if ! is_display_host; then
    log_info "skipping vicinae (not a display host)"
    return 0
  fi
  if command_exists vicinae; then
    log_info "vicinae already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install vicinae (dry-run)"
    return 0
  fi

  if is_arch; then
    aur_install vicinae-bin
  elif is_debian_like; then
    log_warn "vicinae has no upstream .deb yet; build from source not yet automated"
    log_warn "see https://github.com/vicinaehq/vicinae for manual build steps"
    return 1
  else
    log_error "no vicinae install path for $DISTRO"
    return 1
  fi
}

install_vicinae
