#!/usr/bin/env bash
set -euo pipefail

# LazyVim helper that ensures tooling before the config is cloned.
LAZYVIM_COMMON_DEPS=(ripgrep fd unzip)
declare -A LAZYVIM_LINUX_EXTRAS=(
  [arch]="nodejs npm python python-pip"
  [ubuntu]="nodejs npm python3 python3-pip"
  [debian]="nodejs npm python3 python3-pip"
)
declare -A LAZYVIM_BUILD_DEPS=(
  [arch]="ninja libtool autoconf automake cmake gcc pkg-config unzip"
  [ubuntu]="ninja-build libtool libtool-bin autoconf automake cmake g++ pkg-config unzip"
  [debian]="ninja-build libtool libtool-bin autoconf automake cmake g++ pkg-config unzip"
)

run_lazyvim_brew_deps() {
  local dry_run="${DRY_RUN:-false}"
  local packages=(git neovim ripgrep fd node python3)
  if [[ "$dry_run" == true ]]; then
    log_info "Would install LazyVim Homebrew deps: ${packages[*]} (dry-run)"
    return
  fi
  log_info "Installing LazyVim dependencies via Homebrew"
  brew install "${packages[@]}"

  # Check if we're in a virtualenv (--user flag doesn't work in virtualenvs)
  if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    python3 -m pip install --user --upgrade pynvim
  else
    python3 -m pip install --upgrade pynvim
  fi
}

install_lazyvim_dependencies() {
  install_package neovim
  case "$DISTRO" in
  macos)
    run_lazyvim_brew_deps
    return
    ;;
  esac

  local deps=()
  deps+=("${LAZYVIM_COMMON_DEPS[@]}")

  # Temporarily disable unbound variable checking for associative array access
  set +u

  # Check if distro-specific extras exist
  if [[ -n "${LAZYVIM_LINUX_EXTRAS[$DISTRO]:-}" ]]; then
    IFS=' ' read -r -a extras <<<"${LAZYVIM_LINUX_EXTRAS[$DISTRO]}"
    deps+=("${extras[@]}")
  fi

  # Check if distro-specific build deps exist
  if [[ -n "${LAZYVIM_BUILD_DEPS[$DISTRO]:-}" ]]; then
    IFS=' ' read -r -a build <<<"${LAZYVIM_BUILD_DEPS[$DISTRO]}"
    deps+=("${build[@]}")
  fi

  # Re-enable unbound variable checking
  set -u

  install_packages "${deps[@]}"

  local python_cmd=python3
  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    python_cmd=python
  fi
  local dry_run="${DRY_RUN:-false}"
  if [[ "$dry_run" == true ]]; then
    log_info "Would install pynvim via $python_cmd -m pip (dry-run)"
    return
  fi
  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    log_error "Python interpreter not found; cannot install pynvim"
    return 1
  fi

  # Verify pip is available
  if ! "$python_cmd" -m pip --version &>/dev/null; then
    log_warn "pip not available, skipping pynvim installation"
    return 0
  fi

  # Check if we're in a virtualenv (--user flag doesn't work in virtualenvs)
  local pip_args=(install --upgrade pynvim)
  if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    # Not in a virtualenv, use --user flag
    pip_args=(install --user --upgrade pynvim)
  fi

  # Try to install pynvim, handle PEP 668 and other errors gracefully
  "$python_cmd" -m pip "${pip_args[@]}" 2>/dev/null || {
    log_warn "Could not install pynvim (may be externally-managed Python)"
    log_info "Install manually with: pipx install pynvim or python3 -m venv"
  }
}

install_lazyvim_stack() {
  install_lazyvim_dependencies
  install_package lazyvim
}
