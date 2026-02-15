#!/usr/bin/env bash
set -euo pipefail

# wiremix - Audio control TUI for PipeWire
# https://github.com/wiremix/wiremix

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/os.sh"

install_wiremix() {
    # Check if already installed
    if command -v wiremix &> /dev/null; then
        log_info "wiremix already installed"
        return 0
    fi

    log_info "Installing wiremix..."

    local dry_run="${DRY_RUN:-false}"

    # Try package manager first on Arch (might be in AUR)
    if is_arch; then
        if command -v yay &> /dev/null; then
            if [[ "$dry_run" == true ]]; then
                log_info "Would try installing wiremix via yay (dry-run)"
            else
                log_info "Trying to install wiremix via yay..."
                yay -S --noconfirm wiremix || true
            fi
        fi
    fi

    # Fallback to cargo if not installed yet
    if ! command -v wiremix &> /dev/null; then
        if ! command -v cargo &> /dev/null; then
            log_warn "Rust/Cargo required for wiremix installation"
            log_info "Install rustup first, then: cargo install wiremix"
            return 0
        fi

        if [[ "$dry_run" == true ]]; then
            log_info "Would install wiremix via cargo (dry-run)"
            return 0
        fi

        log_info "Building wiremix from cargo..."
        if cargo install wiremix 2>&1; then
            log_info "wiremix built and installed successfully"
            return 0
        else
            log_warn "Failed to build wiremix from cargo"
            log_info "Make sure pipewire development headers are installed:"
            log_info "  Ubuntu: sudo apt install libpipewire-0.3-dev"
            log_info "  Arch: pipewire package includes headers"
            return 0
        fi
    fi

    log_info "wiremix installation complete"
    return 0
}

install_wiremix
