#!/usr/bin/env bash
set -euo pipefail

# llama-swap (https://github.com/mostlygeek/llama-swap) — proxy that swaps
# llama.cpp models on demand.

install_llama_swap() {
  if command_exists llama-swap; then
    log_info "llama-swap already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install llama-swap (dry-run)"
    return 0
  fi

  if is_arch; then
    aur_install llama-swap
    return 0
  fi

  if ! command_exists go; then
    log_info "go not present; installing"
    if is_macos; then
      brew install go
    elif is_debian_like; then
      sudo apt-get install -y golang-go
    fi
  fi
  if ! command_exists go; then
    log_error "go install failed; cannot build llama-swap"
    return 1
  fi
  # Build into user GOBIN (no sudo for fetch/compile of upstream module),
  # then sudo-install just the resulting binary into /usr/local/bin.
  local userbin
  userbin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"
  mkdir -p "$userbin"
  GOBIN="$userbin" go install github.com/mostlygeek/llama-swap@latest
  sudo install -m 755 "$userbin/llama-swap" /usr/local/bin/llama-swap
}

install_llama_swap
