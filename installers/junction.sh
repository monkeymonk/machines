#!/usr/bin/env bash
set -euo pipefail

# Junction - Application chooser for opening links
# Available as Flatpak: re.sonny.Junction

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/os.sh"

install_junction() {
  local dry_run="${DRY_RUN:-false}"
  local flatpak_id="re.sonny.Junction"

  # Check if already installed via Flatpak
  if command -v flatpak >/dev/null 2>&1; then
    if flatpak list --app | grep -q "$flatpak_id"; then
      log_info "Junction already installed (Flatpak)"
      return 0
    fi
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install Junction via Flatpak (dry-run)"
    return 0
  fi

  if is_macos; then
    log_warn "Junction is not available on macOS"
    log_info "Consider using 'Choosy' or 'Browserosaurus' instead"
    return 0
  fi

  # Ensure Flatpak is installed
  if ! command -v flatpak >/dev/null 2>&1; then
    log_info "Installing Flatpak (required for Junction)..."
    if is_arch; then
      sudo pacman -S --needed --noconfirm flatpak
    elif is_debian_like; then
      sudo apt-get install -y flatpak
    else
      log_error "Flatpak installation not supported on this distro"
      return 1
    fi
  fi

  # Check if system bus is available (required for flatpak)
  if ! flatpak remote-list &>/dev/null; then
    log_warn "System bus not available, skipping Junction installation"
    log_info "Flatpak requires systemd/dbus which may not be available in containers"
    return 0
  fi

  # Add Flathub repository if not already added
  if ! flatpak remote-list | grep -q flathub; then
    log_info "Adding Flathub repository..."
    if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then
      log_warn "Failed to add Flathub repository, skipping Junction"
      return 0
    fi
  fi

  # Install Junction
  log_info "Installing Junction via Flatpak..."
  if flatpak install -y flathub "$flatpak_id" 2>/dev/null; then
    log_info "Junction installed successfully"
  else
    log_warn "Failed to install Junction (flatpak may not be fully functional)"
  fi
}

install_junction
