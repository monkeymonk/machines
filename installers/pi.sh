#!/usr/bin/env bash
set -euo pipefail

# Pi (https://github.com/earendil-works/pi) — minimal, extensible coding-agent
# CLI. Installed via mise's npm backend so its npm prefix is handled the same
# way as every other mise-managed tool (never lands inside a node version
# directory a runtime bump can delete).
#
# See installers/pi-extensions.sh for the extension set that closes the
# capability gap with Oh My Pi (omp) — LSP, MCP, subagents, TODO, plan mode,
# and Docker sandboxing all ship built into omp but are separate community
# extensions for Pi.

PI_NPM_SPEC="npm:@earendil-works/pi-coding-agent"

install_pi() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists pi; then
    log_info "pi already installed"
    return 0
  fi

  if ! command_exists mise; then
    log_error "mise required to install pi (run: ./install.sh --packages mise)"
    return 1
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install pi via mise ($PI_NPM_SPEC) (dry-run)"
    return 0
  fi

  log_info "Installing pi via mise"
  mise use -g "$PI_NPM_SPEC"
}

install_pi
