#!/usr/bin/env bash
set -euo pipefail

# Distro detection and helpers so scripts can make distro-specific decisions.
detect_distro() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "${ID:-unknown}"
    return
  fi

  local uname
  uname=$(uname -s)
  case "$uname" in
  Linux)
    echo "linux"
    ;;
  Darwin)
    echo "macos"
    ;;
  *)
    echo "unknown"
    ;;
  esac
}

os_codename() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "${VERSION_CODENAME:-${VERSION_ID:-}}"
  fi
}

IS_UBUNTU=false
IS_ARCH=false
IS_DEBIAN=false
IS_MACOS=false
DISTRO=$(detect_distro)
case "$DISTRO" in
ubuntu)
  IS_UBUNTU=true
  ;;
debian)
  IS_DEBIAN=true
  ;;
arch)
  IS_ARCH=true
  ;;
macos)
  IS_MACOS=true
  ;;
*) ;; # leave defaults
esac

is_supported_distro() {
  [[ "$IS_UBUNTU" == true || "$IS_DEBIAN" == true || "$IS_ARCH" == true || "$IS_MACOS" == true ]]
}

is_debian_like() {
  [[ "$IS_UBUNTU" == true || "$IS_DEBIAN" == true ]]
}

is_arch() {
  [[ "$IS_ARCH" == true ]]
}

is_macos() {
  [[ "$IS_MACOS" == true ]]
}

ensure_supported_distro() {
  if ! is_supported_distro; then
    log_error "Unsupported distro: $DISTRO"
    return 1
  fi
}
