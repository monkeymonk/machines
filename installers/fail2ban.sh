#!/usr/bin/env bash
set -euo pipefail

install_fail2ban() {
  local dry_run="${DRY_RUN:-false}"

  # Check if already installed
  if command_exists fail2ban-server; then
    log_info "fail2ban already installed"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install fail2ban (dry-run)"
    return 0
  fi

  log_info "Installing fail2ban"

  # Install package (distro-aware)
  if is_debian_like; then
    pkg_install fail2ban
  elif is_arch; then
    pkg_install fail2ban
  elif is_macos; then
    log_warn "fail2ban not available on macOS, skipping"
    return 0
  else
    log_error "Unsupported distro for fail2ban"
    return 1
  fi

  # Enable and start service
  if command_exists systemctl; then
    if ! systemctl is-active --quiet fail2ban 2>/dev/null; then
      log_info "Enabling and starting fail2ban service"
      sudo systemctl enable fail2ban
      sudo systemctl start fail2ban
    fi
  fi
}

install_fail2ban
