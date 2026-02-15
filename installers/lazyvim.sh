#!/usr/bin/env bash
set -euo pipefail

# LazyVim is a Neovim configuration, not a package
# This installer checks if LazyVim is already set up and optionally installs it

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

install_lazyvim_config() {
    local nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
    local dry_run="${DRY_RUN:-false}"

    # Check if LazyVim (or any Neovim config) is already present
    if [[ -d "$nvim_config_dir" ]]; then
        # Check if it's LazyVim by looking for lazy-lock.json or lazy.lua
        if [[ -f "$nvim_config_dir/lazy-lock.json" ]] || [[ -f "$nvim_config_dir/lua/config/lazy.lua" ]]; then
            log_info "LazyVim already configured"
        else
            log_info "Custom Neovim configuration detected (skipping LazyVim)"
        fi
        return 0
    fi

    # No config exists - offer to install LazyVim starter
    if [[ "$dry_run" == true ]]; then
        log_info "Would check if LazyVim should be installed (dry-run)"
        return 0
    fi

    # In non-interactive mode, skip installation
    if [[ ! -t 0 ]]; then
        log_info "No Neovim config found, but running non-interactively"
        log_info "To install LazyVim manually:"
        log_info "  git clone https://github.com/LazyVim/starter $nvim_config_dir"
        log_info "  rm -rf $nvim_config_dir/.git"
        return 0
    fi

    # Interactive mode - ask user
    echo ""
    echo "LazyVim is not currently installed."
    echo "LazyVim is a Neovim configuration starter template."
    echo ""
    echo "Install LazyVim starter configuration?"
    echo "  1) Yes, install LazyVim starter"
    echo "  2) No, skip (I'll configure Neovim myself)"
    echo ""
    read -p "Choice [1-2]: " choice

    case "$choice" in
        1)
            log_info "Installing LazyVim starter configuration..."
            git clone https://github.com/LazyVim/starter "$nvim_config_dir"
            rm -rf "$nvim_config_dir/.git"
            log_info "LazyVim starter installed at $nvim_config_dir"
            log_info "Run 'nvim' to complete the setup (plugins will auto-install)"
            ;;
        2)
            log_info "Skipping LazyVim installation"
            ;;
        *)
            log_warn "Invalid choice, skipping LazyVim installation"
            ;;
    esac
}

# Run the installation function
install_lazyvim_config
