#!/usr/bin/env bash
set -euo pipefail

# Install and configure ufw with a sensible default profile.
# Idempotent: only initialises a fresh ufw. If it's already active or has any
# rules, leave the user's config alone — re-running the bootstrap should not
# blast a customised firewall.

_ufw_install_pkg() {
  if command_exists ufw; then
    return 0
  fi
  log_info "Installing ufw"
  if is_debian_like || is_arch; then
    pkg_install ufw
  elif is_macos; then
    log_warn "ufw not available on macOS, skipping"
    return 1
  else
    log_error "Unsupported distro for ufw"
    return 1
  fi
}

_ufw_already_configured() {
  # Treat ufw as configured if it's active OR has any user-added rules.
  local status
  status=$(sudo ufw status numbered 2>/dev/null || true)
  if grep -q "^Status: active" <<<"$status"; then
    return 0
  fi
  if grep -qE "^\[ *[0-9]+\]" <<<"$status"; then
    return 0
  fi
  return 1
}

_ufw_apply_default_profile() {
  log_info "Configuring ufw firewall (default profile)"
  sudo ufw --force reset
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw limit ssh
  log_info "Enabling ufw"
  if ! sudo ufw --force enable; then
    log_warn "ufw enable failed (kernel iptables modules unavailable?); rules saved, enable manually"
    return 0
  fi
  log_info "UFW configured: deny incoming, allow outgoing, rate-limit SSH"
}

install_ufw() {
  local dry_run="${DRY_RUN:-false}"

  if [[ "$dry_run" == true ]]; then
    log_info "Would install and configure ufw (dry-run)"
    return 0
  fi

  _ufw_install_pkg || return 0

  if _ufw_already_configured; then
    log_info "ufw already configured; leaving existing rules untouched"
    return 0
  fi

  _ufw_apply_default_profile
}

install_ufw
