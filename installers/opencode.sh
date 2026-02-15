#!/usr/bin/env bash
set -euo pipefail

install_opencode() {
  local dry_run="${DRY_RUN:-false}"

  if ! command_exists opencode; then
    log_info "Installing OpenCode"
    if [[ "$dry_run" == true ]]; then
      log_info "Would install OpenCode via install script (dry-run)"
    else
      curl -fsSL https://opencode.ai/install | bash
    fi
  else
    log_info "OpenCode already installed"
  fi

  # Check if oh-my-opencode is already configured
  local opencode_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  if [[ -f "$opencode_config_dir/config.json" ]] || [[ -f "$opencode_config_dir/settings.json" ]]; then
    log_info "oh-my-opencode already configured"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Skipping oh-my-opencode setup (dry-run)"
    return 0
  fi

  # In non-interactive mode, skip oh-my-opencode setup
  if [[ ! -t 0 ]]; then
    log_info "Skipping oh-my-opencode setup (non-interactive mode)"
    log_info "Run 'npx oh-my-opencode install' or 'bunx oh-my-opencode install' manually"
    return 0
  fi

  local installer_cmd=""
  if command_exists bunx; then
    installer_cmd="bunx oh-my-opencode install"
  elif command_exists npx; then
    installer_cmd="npx oh-my-opencode install"
  else
    log_warn "bunx or npx not found, skipping oh-my-opencode setup"
    log_info "Install Node.js/npm or Bun, then run: npx oh-my-opencode install"
    return 0
  fi

  log_info "Running oh-my-opencode installer"
  log_info "This will guide you through interactive setup..."

  # Run the installer without flags - let it be fully interactive
  $installer_cmd
}

install_opencode
