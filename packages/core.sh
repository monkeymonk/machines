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
  xz-utils
  "7zip,arch:p7zip,debian:p7zip-full"

  # File utilities
  file

  # Media tools
  ffmpeg
  imagemagick

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

# Cargo packages (Rust-based CLI tools)
CARGO_PACKAGES=(
  bat          # Better cat with syntax highlighting
  fd-find      # Modern find alternative
  exa          # Modern ls alternative
  bob-nvim     # Neovim version manager
  zoxide       # Smarter cd command
  yazi-fm      # Terminal file manager
)

install_cargo_packages() {
  local dry_run="${DRY_RUN:-false}"

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

  for pkg in "${CARGO_PACKAGES[@]}"; do
    # Extract command name from package name (e.g., "bob-nvim" -> "bob")
    local cmd_name
    if [[ "$pkg" == *"-"* ]]; then
      cmd_name="${pkg%%-*}"
    else
      cmd_name="$pkg"
    fi

    if command -v "$cmd_name" >/dev/null 2>&1; then
      log_info "$pkg already installed"
      continue
    fi

    if [[ "$dry_run" == true ]]; then
      log_info "Would install cargo package: $pkg (dry-run)"
    else
      log_info "Installing cargo package: $pkg"
      cargo install "$pkg"
    fi
  done
}

install_core_packages() {
  # Install rustup first (needed for cargo packages)
  install_package rustup

  # Install system packages with distro-aware mapping
  for pkg in "${CORE_PACKAGES[@]}"; do
    install_package_with_mapping "$pkg"
  done

  # Install cargo packages (requires rustup)
  install_cargo_packages

  # Install version managers
  install_package nvm
}
