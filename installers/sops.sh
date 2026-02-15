#!/usr/bin/env bash
set -euo pipefail

install_sops() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists sops; then
    log_info "sops already installed"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install sops (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install sops
    return 0
  fi

  if is_macos; then
    pkg_install sops
    return 0
  fi

  # Debian/Ubuntu: install from GitHub release
  log_info "Installing sops from GitHub release"

  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      log_error "Unsupported architecture: $arch"
      return 1
      ;;
  esac

  local version="v3.9.4"
  local url="https://github.com/getsops/sops/releases/download/${version}/sops-${version}.linux.${arch}"
  local temp_file
  temp_file="$(mktemp)"

  log_info "Downloading sops ${version} for ${arch}"

  if ! curl -fSL "$url" -o "$temp_file"; then
    log_error "Failed to download sops"
    rm -f "$temp_file"
    return 1
  fi

  sudo install -m 0755 "$temp_file" /usr/local/bin/sops
  rm -f "$temp_file"

  log_info "sops installed successfully"
}

install_sops
