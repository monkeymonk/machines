#!/usr/bin/env bash
set -euo pipefail

# Arch-specific tweaks that run before package installs.
bootstrap_arch() {
  local dry_run="${DRY_RUN:-false}"

  log_info "Running Arch bootstrap hooks"

  if [[ "$dry_run" == true ]]; then
    log_info "Would enable [multilib] if missing (dry-run)"
    log_info "Would run pacman -Syu (dry-run)"
    return 0
  fi

  enable_multilib_repo
  sudo pacman -Syu --noconfirm
}

# Idempotently uncomment the [multilib] repo block in /etc/pacman.conf.
# CachyOS ships with it pre-enabled; vanilla Arch does not. Required for
# Steam + any lib32-* package (Proton runtime, lib32-mangohud, lib32-vulkan-*).
enable_multilib_repo() {
  local conf="/etc/pacman.conf"
  if grep -Eq '^\s*\[multilib\]\s*$' "$conf"; then
    log_debug "multilib repo already enabled"
    return 0
  fi
  if ! grep -Eq '^\s*#\s*\[multilib\]\s*$' "$conf"; then
    log_warn "no [multilib] block found in $conf; leaving alone"
    return 0
  fi
  log_info "Enabling [multilib] repo in $conf"
  # Uncomment the [multilib] header and the immediately-following Include line.
  sudo sed -i -E '/^\s*#\s*\[multilib\]\s*$/,/^\s*#?\s*Include\s*=\s*\/etc\/pacman\.d\/mirrorlist\s*$/ s/^\s*#\s*//' "$conf"
}
