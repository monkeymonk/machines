#!/usr/bin/env bash
set -euo pipefail

# bluetuith — Bluetooth management TUI (https://github.com/darkhz/bluetuith).
# AUR-only on Linux; not packaged for Debian/Ubuntu.

install_bluetuith() {
  if command_exists bluetui || command_exists bluetuith; then
    log_info "bluetuith already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install bluetuith (dry-run)"
    return 0
  fi

  if is_arch; then
    aur_install bluetuith
    return 0
  fi

  log_info "bluetuith not packaged for $DISTRO; skipping (build from source if needed)"
}

install_bluetuith
