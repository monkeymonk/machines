#!/usr/bin/env bash
set -euo pipefail

# Package manager discovery and install helpers.
PKG_MANAGER="unknown"
PKG_INSTALL_CMD=""
PKG_UPDATE_CMD=""
REPO_ROOT=${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)}
INSTALLERS_DIR="$REPO_ROOT/installers"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

package_installed() {
  local package_name="$1"

  if [[ -z "$PKG_MANAGER" ]]; then
    detect_pkg_manager
  fi

  case "$PKG_MANAGER" in
    apt)
      dpkg -l "$package_name" 2>/dev/null | grep -q "^ii"
      return $?
      ;;
    pacman)
      pacman -Q "$package_name" >/dev/null 2>&1
      return $?
      ;;
    brew)
      brew list "$package_name" >/dev/null 2>&1
      return $?
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_command() {
  local command_name="$1"
  local package_name="$2"
  if command_exists "$command_name"; then
    log_info "$command_name already installed"
    return 0
  fi
  install_package "$package_name"
}

detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
    PKG_INSTALL_CMD="sudo apt-get install -y"
    PKG_UPDATE_CMD="sudo apt-get update"
  elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
    PKG_INSTALL_CMD="sudo pacman -S --needed --noconfirm"
    PKG_UPDATE_CMD="sudo pacman -Sy"
  elif command -v brew >/dev/null 2>&1; then
    PKG_MANAGER="brew"
    PKG_INSTALL_CMD="brew install"
    PKG_UPDATE_CMD="brew update"
  else
    log_error "No supported package manager found"
    return 1
  fi
}

pkg_update() {
  local dry_run="${DRY_RUN:-false}"
  [[ -z "$PKG_UPDATE_CMD" ]] && detect_pkg_manager
  if [[ "$dry_run" == true ]]; then
    log_info "Skipping package cache update (dry-run mode)"
    return 0
  fi
  log_info "Updating package cache with $PKG_MANAGER"
  local IFS=' '
  read -r -a updater <<<"$PKG_UPDATE_CMD"
  "${updater[@]}"
}

pkg_install() {
  local name="$1"
  [[ -z "$PKG_INSTALL_CMD" ]] && detect_pkg_manager

  # Check if already installed
  if package_installed "$name"; then
    log_info "$name already installed"
    return 0
  fi

  log_info "Installing $name via $PKG_MANAGER"
  local IFS=' '
  read -r -a installer <<<"$PKG_INSTALL_CMD"
  "${installer[@]}" "$name"
}

install_package() {
  local name="$1"
  local installer_path="$INSTALLERS_DIR/${name}.sh"
  local dry_run="${DRY_RUN:-false}"
  if [[ -f "$installer_path" ]]; then
    if [[ "$dry_run" == true ]]; then
      log_info "Would run custom installer for $name (dry-run mode)"
      return 0
    fi
    log_info "Running custom installer for $name"
    # shellcheck disable=SC1090
    source "$installer_path"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install $name via $PKG_MANAGER (dry-run mode)"
    return 0
  fi

  pkg_install "$name"
}

install_packages() {
  if [[ $# -eq 0 ]]; then
    log_debug "No packages passed to install_packages"
    return 0
  fi

  for pkg in "$@"; do
    install_package "$pkg"
  done
}

install_package_with_mapping() {
  local mapping="$1"
  # Format: "default-name" or "default-name,arch:arch-name,debian:debian-name,macos:macos-name"

  local package_name="$mapping"

  # Check if mapping contains distro-specific names
  if [[ "$mapping" == *","* ]]; then
    # Has mappings, parse them
    local IFS=','
    read -r -a parts <<< "$mapping"
    package_name="${parts[0]}"  # default name

    # Look for distro-specific override
    for part in "${parts[@]:1}"; do
      if [[ "$part" == arch:* ]] && is_arch; then
        package_name="${part#arch:}"
        break
      elif [[ "$part" == debian:* ]] && is_debian_like; then
        package_name="${part#debian:}"
        break
      elif [[ "$part" == macos:* ]] && is_macos; then
        package_name="${part#macos:}"
        break
      fi
    done
  fi

  install_package "$package_name"
}
