#!/usr/bin/env bash
set -euo pipefail

install_yazi() {
  local dry_run="${DRY_RUN:-false}"

  # Check if already installed
  if command_exists yazi; then
    log_info "yazi already installed"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install yazi (dry-run)"
    return 0
  fi

  log_info "Installing yazi"

  # Detect architecture
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64)
      arch="x86_64"
      ;;
    aarch64|arm64)
      arch="aarch64"
      ;;
    *)
      log_error "Unsupported architecture: $arch"
      return 1
      ;;
  esac

  # Download latest release
  local version="v0.4.2"  # Update as needed
  local url="https://github.com/sxyazi/yazi/releases/download/${version}/yazi-${arch}-unknown-linux-gnu.zip"
  local temp_dir
  temp_dir="$(mktemp -d)"

  log_info "Downloading yazi ${version} for ${arch}"

  if ! curl -L "$url" -o "${temp_dir}/yazi.zip"; then
    log_error "Failed to download yazi"
    rm -rf "$temp_dir"
    return 1
  fi

  # Extract and install
  unzip -q "${temp_dir}/yazi.zip" -d "$temp_dir"
  sudo mv "${temp_dir}/yazi-${arch}-unknown-linux-gnu/yazi" /usr/local/bin/
  sudo mv "${temp_dir}/yazi-${arch}-unknown-linux-gnu/ya" /usr/local/bin/
  sudo chmod +x /usr/local/bin/yazi /usr/local/bin/ya

  # Cleanup
  rm -rf "$temp_dir"

  log_info "yazi installed successfully"
}

install_yazi
