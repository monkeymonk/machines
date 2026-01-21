#!/usr/bin/env bash
set -euo pipefail

install_neovim() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists nvim; then
    log_info "Neovim already installed"
    return 0
  fi

  log_info "Installing Neovim"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install Neovim (dry-run)"
    return 0
  fi

  if is_arch; then
    pkg_install neovim
  elif is_debian_like; then
    install_neovim_from_source
  elif is_macos; then
    if command_exists brew; then
      log_info "Installing Neovim via Homebrew"
      brew install neovim
    else
      log_warn "Homebrew not found; falling back to package manager"
      pkg_install neovim
    fi
  else
    log_warn "No distro-specific Neovim installer for $DISTRO; using package manager"
    pkg_install neovim
  fi
}

install_neovim_from_source() {
  log_info "Installing Debian/Ubuntu build dependencies"
  install_packages ninja-build libtool libtool-bin autoconf automake cmake g++ pkg-config unzip
  local tmpdir
  tmpdir=$(mktemp -d -t neovim-build-XXXXXX)
  trap 'rm -rf "$tmpdir"' EXIT
  log_info "Cloning Neovim sources into $tmpdir"
  git clone https://github.com/neovim/neovim.git "$tmpdir/neovim"
  pushd "$tmpdir/neovim" >/dev/null
  make CMAKE_BUILD_TYPE=Release
  sudo make install
  popd >/dev/null
  trap - EXIT
  rm -rf "$tmpdir"
}

install_neovim
