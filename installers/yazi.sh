#!/usr/bin/env bash
set -euo pipefail

# yazi terminal file manager. In Arch and Homebrew package repos directly;
# Debian/Ubuntu fall back to upstream tarball (latest, not pinned).

install_yazi() {
  if command_exists yazi; then
    log_info "yazi already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install yazi (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install yazi
    return 0
  fi
  if is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew required for yazi on macOS"
      return 1
    fi
    brew install yazi
    return 0
  fi
  if ! is_debian_like; then
    log_error "no yazi install path for $DISTRO"
    return 1
  fi

  local arch
  arch=$(uname -m)
  case "$arch" in
  x86_64) arch="x86_64" ;;
  aarch64 | arm64) arch="aarch64" ;;
  *)
    log_error "unsupported architecture for yazi: $arch"
    return 1
    ;;
  esac

  log_info "fetching latest yazi release for $arch"
  local tag url tmp
  tag=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest |
    grep -oP '"tag_name"\s*:\s*"\K[^"]+' | head -1)
  if [[ -z "$tag" ]]; then
    log_error "could not resolve latest yazi tag from GitHub API"
    return 1
  fi
  url="https://github.com/sxyazi/yazi/releases/download/${tag}/yazi-${arch}-unknown-linux-gnu.zip"
  tmp=$(mktemp -d)
  if ! curl -fsSL "$url" -o "$tmp/yazi.zip"; then
    log_error "download failed: $url"
    rm -rf "$tmp"
    return 1
  fi
  unzip -q "$tmp/yazi.zip" -d "$tmp"
  sudo install -m 755 "$tmp/yazi-${arch}-unknown-linux-gnu/yazi" /usr/local/bin/yazi
  sudo install -m 755 "$tmp/yazi-${arch}-unknown-linux-gnu/ya" /usr/local/bin/ya
  rm -rf "$tmp"
  log_info "yazi $tag installed to /usr/local/bin"
}

install_yazi
