#!/usr/bin/env bash
set -euo pipefail

install_nvm() {
  local dry_run="${DRY_RUN:-false}"
  local nvm_dir="$HOME/.nvm"

  if [[ -d "$nvm_dir" ]]; then
    log_info "nvm already installed at $nvm_dir"
  else
    log_info "Installing nvm"
    if [[ "$dry_run" == true ]]; then
      log_info "Would install nvm via install script (dry-run)"
    else
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    fi
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install latest LTS Node via nvm (dry-run)"
    return 0
  fi

  if [[ -s "$nvm_dir/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    source "$nvm_dir/nvm.sh"
  else
    log_error "nvm.sh not found; cannot configure Node LTS"
    return 1
  fi

  log_info "Installing latest Node LTS"
  nvm install --lts
  nvm alias default 'lts/*'
}

install_nvm
