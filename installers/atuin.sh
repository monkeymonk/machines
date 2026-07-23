#!/usr/bin/env bash
set -euo pipefail

_ATUIN_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/atuin"
_ATUIN_CONFIG="$_ATUIN_CONFIG_DIR/config.toml"

# Write Atuin's config once. Never clobber an existing user config.
_atuin_write_config() {
  if [[ -f "$_ATUIN_CONFIG" ]]; then
    log_info "atuin config already present at $_ATUIN_CONFIG"
    return 0
  fi
  mkdir -p "$_ATUIN_CONFIG_DIR"
  cat >"$_ATUIN_CONFIG" <<'EOF'
# Atuin — managed by installers/atuin.sh (machines repo).
# Docs: https://docs.atuin.sh/configuration/config/

## Ctrl-R: search full history; press Ctrl-R again to cycle filter modes
## (global -> host -> session -> directory -> workspace).
filter_mode = "global"

## Up arrow: scope recall to the current directory (across sessions).
## Swap to "session" (this shell only) or "workspace" (git repo root).
filter_mode_shell_up_key_binding = "directory"

## Respect the shell's vi keymap (zsh-vi-mode).
keymap_mode = "auto"

## Press Enter to run the selected command immediately (vs. edit first).
enter_accept = true

## Compact inline UI instead of fullscreen.
style = "compact"
inline_height = 25

## Fuzzy search.
search_mode = "fuzzy"

## Commands never recorded (ported from the shell's HISTORY_IGNORE).
history_filter = [
  "^ls$",
  "^cd$",
  "^cd -$",
  "^cd \\.\\.$",
  "^pwd$",
  "^exit$",
  "^history$",
  "^sudo reboot$",
]
EOF
  log_info "wrote $_ATUIN_CONFIG"
}

install_atuin() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists atuin; then
    log_info "atuin already installed"
  else
    log_info "Installing atuin"
    if [[ "$dry_run" == true ]]; then
      log_info "Would install atuin (dry-run)"
      return 0
    fi

    if is_macos; then
      if ! command_exists brew; then
        log_error "Homebrew not available; cannot install atuin"
        return 1
      fi
      brew install atuin
    elif is_arch; then
      pkg_install atuin
    elif is_debian_like; then
      # Not in Debian stable apt; use the official installer (mirrors how
      # mise/uv route to upstream installers on Debian).
      curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    else
      pkg_install atuin
    fi
  fi

  [[ "$dry_run" == true ]] && return 0

  _atuin_write_config

  # One-time import of existing shell history — only when Atuin's DB is empty,
  # so re-running the installer never duplicates entries. Best-effort.
  if command_exists atuin && [[ -z "$(atuin history list 2>/dev/null | head -n1)" ]]; then
    atuin import auto >/dev/null 2>&1 || \
      log_warn "atuin import auto failed; import later with: atuin import auto"
  fi
}

install_atuin
