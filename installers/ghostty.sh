#!/usr/bin/env bash
set -euo pipefail

install_go_runtime() {
  local dry_run="${DRY_RUN:-false}"
  if command_exists go; then
    log_info "Go already installed"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install Go (dry-run)"
    return 0
  fi

  if is_macos; then
    if command_exists brew; then
      log_info "Installing Go via Homebrew"
      brew install go
    else
      log_warn "Homebrew not found; skipping Go install"
    fi
  elif is_debian_like; then
    install_package golang-go
  else
    install_package go
  fi
}

install_ghostty() {
  log_info "Installing Ghostty"
  install_go_runtime
  local dry_run="${DRY_RUN:-false}"
  if [[ "$dry_run" == true ]]; then
    log_info "Would build Ghostty via 'go install' (dry-run mode)"
    return 0
  fi

  if ! command_exists go; then
    log_error "Go compiler not found; Ghostty build requires Go"
    return 1
  fi
  local gobin
  gobin=$(go env GOBIN 2>/dev/null || true)
  if [[ -z "$gobin" ]]; then
    local gopath
    gopath=$(go env GOPATH 2>/dev/null || true)
    if [[ -z "$gopath" ]]; then
      gopath="$HOME/go"
    fi
    gobin="$gopath/bin"
  fi
  log_info "Go binaries will land in $gobin"
  GOBIN="$gobin" go install github.com/creack/ghostty@latest
  log_info "Ghostty installed; ensure $gobin is in PATH"
}

install_ghostty
