#!/usr/bin/env bash
set -euo pipefail

# bluetuith - Bluetooth management TUI
# https://github.com/darkhz/bluetuith
# Available in Arch AUR, not in Ubuntu repos

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/os.sh"

install_bluetuith() {
    # Check if already installed
    if command -v bluetui &> /dev/null || command -v bluetuith &> /dev/null; then
        log_info "bluetuith already installed"
        return 0
    fi

    local dry_run="${DRY_RUN:-false}"

    # Try package manager on Arch (available in AUR)
    if is_arch; then
        if command -v yay &> /dev/null; then
            if [[ "$dry_run" == true ]]; then
                log_info "Would install bluetuith via yay (dry-run)"
                return 0
            fi

            log_info "Installing bluetuith from AUR..."
            if yay -S --noconfirm bluetuith; then
                log_info "bluetuith installed from AUR"
                return 0
            else
                log_warn "Failed to install bluetuith from AUR"
            fi
        else
            log_info "yay not found - bluetuith requires AUR helper on Arch"
        fi
    fi

    # Not available on other distros via package manager
    log_info "bluetuith not available in package repositories (Arch AUR only)"
    log_info "Skipping bluetuith installation"
    log_info ""
    log_info "To install manually, build from source:"
    log_info "  git clone https://github.com/darkhz/bluetuith"
    log_info "  cd bluetuith && make"
    log_info "  sudo make install"
    log_info ""
    log_info "For Bluetooth management, you can use:"
    log_info "  - bluetoothctl (command-line)"
    log_info "  - blueman (GUI - already installed)"

    return 0
}

install_bluetuith
