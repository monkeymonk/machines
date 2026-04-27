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

# Resolves a mapping spec to a package name and install method, then dispatches.
#
# Format:
#   "default-name"
#   "default-name,arch:NAME,aur:NAME,debian:NAME,ubuntu:NAME,macos:NAME,macos-cask:NAME"
#
# Resolution per distro:
#   arch family   → arch: > aur: > default. arch: uses pacman, aur: uses paru.
#                   With no override, falls through to pkg_install_or_aur which
#                   tries pacman first, then AUR.
#   ubuntu        → ubuntu: > debian: > default. Always apt.
#   debian        → debian: > default. Always apt.
#   macos         → macos-cask: > macos: > default. cask uses brew --cask.
#
# No SKIP keyword. If a tool can't be cleanly mapped to a package name on every
# distro (needs apt-repo-add, build-from-source, etc.), it belongs in installers/.
#
# Note: an `arch:` override locks the install to pacman only — there is no
# AUR fallback. For AUR-only packages use `aur:NAME`. Without either override
# on Arch, the auto path uses pkg_install_or_aur (pacman → AUR).
install_package_with_mapping() {
  local mapping="$1"
  local default_name="$mapping"
  local override_name=""
  local install_method="auto"

  if [[ "$mapping" == *","* ]]; then
    local IFS=','
    read -r -a parts <<<"$mapping"
    default_name="${parts[0]}"

    local has_arch="" has_aur="" has_debian="" has_ubuntu="" has_macos="" has_macos_cask=""
    for part in "${parts[@]:1}"; do
      case "$part" in
      arch:*)       has_arch="${part#arch:}" ;;
      aur:*)        has_aur="${part#aur:}" ;;
      debian:*)     has_debian="${part#debian:}" ;;
      ubuntu:*)     has_ubuntu="${part#ubuntu:}" ;;
      macos:*)      has_macos="${part#macos:}" ;;
      macos-cask:*) has_macos_cask="${part#macos-cask:}" ;;
      esac
    done

    if is_arch; then
      if [[ -n "$has_arch" ]]; then
        override_name="$has_arch"
        install_method="pacman"
      elif [[ -n "$has_aur" ]]; then
        override_name="$has_aur"
        install_method="aur"
      fi
    elif is_debian_like; then
      if [[ "$IS_UBUNTU" == true && -n "$has_ubuntu" ]]; then
        override_name="$has_ubuntu"
      elif [[ -n "$has_debian" ]]; then
        override_name="$has_debian"
      fi
    elif is_macos; then
      if [[ -n "$has_macos_cask" ]]; then
        override_name="$has_macos_cask"
        install_method="brew_cask"
      elif [[ -n "$has_macos" ]]; then
        override_name="$has_macos"
      fi
    fi
  fi

  local name="${override_name:-$default_name}"

  case "$install_method" in
  pacman)
    pkg_install "$name"
    ;;
  aur)
    aur_install "$name"
    ;;
  brew_cask)
    if [[ "${DRY_RUN:-false}" == true ]]; then
      log_info "Would install $name via brew --cask (dry-run)"
      return 0
    fi
    if package_installed "$name"; then
      log_info "$name already installed"
      return 0
    fi
    log_info "Installing $name via brew --cask"
    brew install --cask "$name"
    ;;
  auto)
    if is_arch; then
      pkg_install_or_aur "$name"
    else
      install_package "$name"
    fi
    ;;
  esac
}

# On Arch-family: try pacman official repos first (cheap local lookup via
# `pacman -Si`), fall back to AUR via paru. Idempotent.
pkg_install_or_aur() {
  local name="$1"
  if ! is_arch; then
    log_error "pkg_install_or_aur called on non-Arch distro ($DISTRO)"
    return 1
  fi
  if package_installed "$name"; then
    log_info "$name already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would resolve $name via pacman→AUR (dry-run)"
    return 0
  fi
  if pacman -Si "$name" >/dev/null 2>&1; then
    pkg_install "$name"
  else
    log_info "$name not in pacman repos, falling back to AUR"
    aur_install "$name"
  fi
}

# Install a package from the AUR via paru. Bootstraps paru on first use.
# Errors loudly off Arch-family — installers must dispatch correctly.
aur_install() {
  local name="$1"
  if ! is_arch; then
    log_error "aur_install called on non-Arch distro ($DISTRO); installer must dispatch"
    return 1
  fi
  if package_installed "$name"; then
    log_info "$name already installed (AUR)"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install $name via AUR (dry-run)"
    return 0
  fi
  aur_bootstrap_paru
  log_info "Installing $name via AUR (paru)"
  paru -S --needed --noconfirm "$name"
}

# Idempotent paru install via makepkg. No-op if already present.
# Tries paru-bin first (precompiled) and falls back to building paru from
# source if the binary fails its smoke test — this happens periodically when
# pacman bumps libalpm's soname before upstream paru-bin is rebuilt.
aur_bootstrap_paru() {
  if command_exists paru && paru -V >/dev/null 2>&1; then
    return 0
  fi
  log_info "Bootstrapping paru AUR helper"
  command_exists git || pkg_install git
  command_exists makepkg || pkg_install base-devel

  _aur_build_pkg() {
    local pkg="$1"
    local builddir
    builddir=$(mktemp -d)
    git clone --depth=1 "https://aur.archlinux.org/${pkg}.git" "$builddir/$pkg"
    (cd "$builddir/$pkg" && makepkg -si --noconfirm)
    rm -rf "$builddir"
  }

  # Try the prebuilt binary package first.
  if _aur_build_pkg paru-bin && paru -V >/dev/null 2>&1; then
    log_info "paru installed (paru-bin)"
    return 0
  fi

  log_warn "paru-bin smoke test failed (libalpm soname mismatch?); building paru from source"
  # Rust is needed to build paru from source.
  command_exists cargo || install_package rustup
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi
  _aur_build_pkg paru
  if ! paru -V >/dev/null 2>&1; then
    log_error "paru build failed; AUR installs will not work"
    return 1
  fi
  log_info "paru installed (from source)"
}

# Idempotent third-party apt repo registration. Used by chrome/brave/vscode-style
# installers. Stores key in /etc/apt/keyrings, source list in /etc/apt/sources.list.d.
#   apt_repo_add <name> <key_url> <repo_line>
apt_repo_add() {
  local name="$1"
  local key_url="$2"
  local repo_line="$3"
  local keyring="/etc/apt/keyrings/${name}.gpg"
  local list="/etc/apt/sources.list.d/${name}.list"

  if [[ ! -f "$keyring" ]]; then
    sudo install -d -m 0755 /etc/apt/keyrings
    log_info "fetching apt key for $name"
    curl -fsSL "$key_url" | sudo gpg --dearmor -o "$keyring"
    sudo chmod 644 "$keyring"
  fi
  if [[ ! -f "$list" ]] || ! grep -qF "$repo_line" "$list" 2>/dev/null; then
    log_info "registering apt source for $name"
    echo "$repo_line" | sudo tee "$list" >/dev/null
    sudo apt-get update
  fi
}

# Download a .deb to a tempdir and install it via apt (which resolves deps).
# Used for one-shot upstream .debs (discord, bitwarden fallback, etc.).
download_and_install_deb() {
  local url="$1"
  local tmp
  tmp=$(mktemp -d)
  local deb="$tmp/pkg.deb"
  log_info "downloading $url"
  if ! curl -fsSL "$url" -o "$deb"; then
    log_error "failed to download $url"
    rm -rf "$tmp"
    return 1
  fi
  sudo apt-get install -y "$deb"
  rm -rf "$tmp"
}
