#!/usr/bin/env bash
set -euo pipefail

# Core packages needed before dotfiles can run
CORE_PACKAGES=(
  # Version control & network
  git
  curl
  wget

  # Build essentials
  "build-essential,arch:base-devel"
  "pkg-config,arch:pkgconf"
  "libssl-dev,arch:openssl"
  cmake

  # Archive tools
  unzip
  tar
  "xz-utils,arch:xz"
  "7zip,arch:p7zip,debian:p7zip-full"

  # File utilities
  file

  # Media tools
  ffmpeg
  imagemagick
  poppler-utils

  # CLI tools
  bash-completion
  fzf
  ripgrep
  fd
  jq
  htop

  # Encryption & config
  age
  yq
)

# Cargo packages as "crate:binary" tuples — the binary is what we check on
# PATH to decide whether the crate is already installed. Defaults to crate
# when no binary is given.
CARGO_PACKAGES=(
  "bat"
  "fd-find:fd"
  "bob-nvim:bob"
  "zoxide"
)

install_cargo_packages() {
  local dry_run="${DRY_RUN:-false}"

  # Allow skipping cargo packages (useful for quick tests)
  if [[ "${SKIP_CARGO_PACKAGES:-false}" == true ]]; then
    log_info "Skipping cargo packages (SKIP_CARGO_PACKAGES=true)"
    return 0
  fi

  # Ensure cargo is available
  if ! command -v cargo >/dev/null 2>&1; then
    log_warn "cargo not found, skipping cargo packages"
    return 0
  fi

  # Source cargo env to ensure it's in PATH
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi

  for entry in "${CARGO_PACKAGES[@]}"; do
    local crate="${entry%%:*}"
    local bin="${entry#*:}"
    [[ "$bin" == "$entry" ]] && bin="$crate"

    if command -v "$bin" >/dev/null 2>&1; then
      log_info "$crate already installed"
      continue
    fi

    if [[ "$dry_run" == true ]]; then
      log_info "Would install cargo package: $crate (dry-run)"
    else
      log_info "Installing cargo package: $crate"
      cargo install "$crate"
    fi
  done
}

install_core_packages() {
  # Install essential prerequisites first (needed by other installers)
  install_package git
  install_package curl
  install_package wget

  # Install rustup (needed for cargo packages)
  install_package rustup

  # Install remaining system packages with distro-aware mapping
  for pkg in "${CORE_PACKAGES[@]}"; do
    # Skip already installed prerequisites
    if [[ "$pkg" == "git" || "$pkg" == "curl" || "$pkg" == "wget" ]]; then
      continue
    fi
    install_package_with_mapping "$pkg"
  done

  # Install cargo packages (requires rustup)
  install_cargo_packages

  # Install yazi (uses installer for distro-specific paths)
  install_package yazi
}
