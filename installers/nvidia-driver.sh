#!/usr/bin/env bash
set -euo pipefail

has_nvidia_gpu() {
  if command_exists lspci; then
    lspci | grep -qi nvidia
    return $?
  fi
  if is_macos; then
    system_profiler SPDisplaysDataType | grep -qi nvidia
    return $?
  fi
  return 1
}

install_nvidia_driver() {
  log_info "Checking for NVIDIA hardware before installing drivers"
  if ! has_nvidia_gpu; then
    log_info "No NVIDIA GPU detected; skipping driver installation"
    return 0
  fi
  local dry_run="${DRY_RUN:-false}"
  if is_macos; then
    log_warn "macOS handles NVIDIA drivers via vendor packages; skipping"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install NVIDIA driver (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install nvidia
  elif is_debian_like; then
    pkg_install nvidia-driver
  else
    pkg_install nvidia-driver
  fi
}

install_nvidia_driver
