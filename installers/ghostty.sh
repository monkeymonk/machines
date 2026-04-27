#!/usr/bin/env bash
set -euo pipefail

# Ghostty terminal emulator (https://ghostty.org). Mitchell Hashimoto's Zig
# project — NOT the github.com/creack/ghostty Go fork an older version of this
# installer used to fetch.

_ghostty_install_zig() {
  if command_exists zig; then
    log_debug "zig already installed"
    return 0
  fi
  log_info "installing zig (required to build ghostty from source)"
  curl -fsSL https://ziglang.org/download/index.json -o /tmp/zig-index.json
  local arch ver url tmp
  arch=$(uname -m)
  case "$arch" in
  x86_64) arch="x86_64" ;;
  aarch64 | arm64) arch="aarch64" ;;
  *)
    log_error "unsupported arch for zig install: $arch"
    return 1
    ;;
  esac
  ver=$(grep -oP '"master"\s*:\s*\{[^}]*"version"\s*:\s*"\K[^"]+' /tmp/zig-index.json | head -1)
  url=$(grep -oP "\"${arch}-linux\"\s*:\s*\{[^}]*\"tarball\"\s*:\s*\"\K[^\"]+" /tmp/zig-index.json | head -1)
  if [[ -z "$url" ]]; then
    log_error "could not resolve zig tarball URL for $arch"
    return 1
  fi
  tmp=$(mktemp -d)
  curl -fsSL "$url" -o "$tmp/zig.tar.xz"
  tar -C "$tmp" -xf "$tmp/zig.tar.xz"
  sudo install -d /opt/zig
  sudo cp -a "$tmp"/zig-*/* /opt/zig/
  sudo ln -sf /opt/zig/zig /usr/local/bin/zig
  rm -rf "$tmp" /tmp/zig-index.json
  log_info "zig $ver installed to /opt/zig"
}

install_ghostty() {
  if command_exists ghostty; then
    log_info "ghostty already installed"
    return 0
  fi

  if ! is_gui_capable; then
    log_info "skipping ghostty on non-GUI host"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install ghostty (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install ghostty
  elif is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew required for ghostty on macOS"
      return 1
    fi
    brew install --cask ghostty
  elif is_debian_like; then
    log_info "building ghostty from source (zig)"
    _ghostty_install_zig
    sudo apt-get install -y \
      libgtk-4-dev libadwaita-1-dev gettext blueprint-compiler \
      libxml2-utils git pkg-config
    local src
    src=$(mktemp -d)
    git clone --depth=1 https://github.com/ghostty-org/ghostty "$src/ghostty"
    (cd "$src/ghostty" && zig build -Doptimize=ReleaseFast)
    sudo install -m 755 "$src/ghostty/zig-out/bin/ghostty" /usr/local/bin/ghostty
    rm -rf "$src"
    log_info "ghostty built and installed to /usr/local/bin/ghostty"
  else
    log_error "no ghostty install path for $DISTRO"
    return 1
  fi
}

install_ghostty
