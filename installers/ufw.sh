#!/usr/bin/env bash
set -euo pipefail

install_ufw() {
  local dry_run="${DRY_RUN:-false}"

  # Check if already installed and configured
  if command_exists ufw; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
      log_info "ufw already installed and configured"
      return 0
    fi
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install and configure ufw (dry-run)"
    return 0
  fi

  # Install if needed
  if ! command_exists ufw; then
    log_info "Installing ufw"
    if is_debian_like; then
      pkg_install ufw
    elif is_arch; then
      pkg_install ufw
    elif is_macos; then
      log_warn "ufw not available on macOS, skipping"
      return 0
    else
      log_error "Unsupported distro for ufw"
      return 1
    fi
  fi

  # Configure firewall
  log_info "Configuring ufw firewall"
  sudo ufw --force reset
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw limit ssh

  # Enable non-interactively
  log_info "Enabling ufw"
  echo "y" | sudo ufw enable

  log_info "UFW configured: deny incoming, allow outgoing, rate-limit SSH"
}

install_ufw
