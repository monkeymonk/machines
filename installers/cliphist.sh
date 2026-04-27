#!/usr/bin/env bash
set -euo pipefail

# cliphist — Wayland clipboard history daemon.

install_cliphist() {
  if ! is_display_host; then
    log_info "skipping cliphist (not a display host)"
    return 0
  fi
  if command_exists cliphist; then
    log_info "cliphist already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install cliphist (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install cliphist
    return 0
  fi
  if ! is_debian_like; then
    log_error "no cliphist install path for $DISTRO"
    return 1
  fi

  if apt-cache show cliphist >/dev/null 2>&1; then
    sudo apt-get install -y cliphist
    return 0
  fi
  log_info "cliphist not in apt; building from go source"
  if ! command_exists go; then
    sudo apt-get install -y golang-go
  fi
  # Build as user, then sudo-install the resulting binary.
  local userbin
  userbin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"
  mkdir -p "$userbin"
  GOBIN="$userbin" go install go.senan.xyz/cliphist@latest
  sudo install -m 755 "$userbin/cliphist" /usr/local/bin/cliphist
}

install_cliphist
