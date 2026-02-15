#!/usr/bin/env bash
set -euo pipefail

# Impala - WiFi management TUI for iwd
# https://github.com/pythops/impala

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"

# Check if already installed
if command -v impala &> /dev/null; then
    log_info "Impala already installed"
    exit 0
fi

log_info "Installing Impala..."

DRY_RUN="${DRY_RUN:-false}"

# Ensure iwd is installed (Impala dependency)
if ! command -v iwctl &> /dev/null; then
    log_info "iwd not found, installing..."
    install_package "iwd"
fi

# Try package manager first on Arch
if is_arch; then
    if command -v yay &> /dev/null; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "Would try installing impala via yay (dry-run)"
        else
            log_info "Trying to install impala via yay..."
            # Try both possible package names
            yay -S --noconfirm impala || yay -S --noconfirm impala-wifi || true
        fi
    fi
fi

# Fallback to cargo if not installed yet
if ! command -v impala &> /dev/null; then
    if ! command -v cargo &> /dev/null; then
        log_error "Rust/Cargo required for Impala installation"
        log_error "Install rustup first (should be in core packages)"
        exit 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would install impala via cargo (dry-run)"
    else
        log_info "Building impala from cargo..."
        cargo install impala
    fi
fi

if command -v impala &> /dev/null || [[ "$DRY_RUN" == true ]]; then
    log_info "Impala installed successfully"
    log_info "Note: Impala requires iwd to be running"
    log_info "To use iwd instead of NetworkManager:"
    log_info "  sudo systemctl disable NetworkManager"
    log_info "  sudo systemctl enable iwd"
    log_info "  sudo systemctl start iwd"
else
    log_error "Failed to install Impala"
    exit 1
fi
