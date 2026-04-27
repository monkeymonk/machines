#!/usr/bin/env bash
set -euo pipefail

# Helpers for systemd / sudoers / privileged-file installs. All idempotent.
# Loaded after lib/log.sh and lib/os.sh so log_* and is_* are available.

# install_sudoers_drop_in <name> <content>
# Validates with `visudo -cf` before installing to /etc/sudoers.d/<name>.
install_sudoers_drop_in() {
  local name="$1"
  local content="$2"
  local target="/etc/sudoers.d/$name"
  local tmp
  tmp=$(mktemp)
  printf '%s\n' "$content" >"$tmp"
  if ! sudo visudo -cf "$tmp" >/dev/null; then
    log_error "sudoers drop-in '$name' failed validation"
    rm -f "$tmp"
    return 1
  fi
  if sudo test -f "$target" && sudo cmp -s "$tmp" "$target"; then
    log_debug "sudoers drop-in '$name' already up to date"
    rm -f "$tmp"
    return 0
  fi
  sudo install -m 440 -o root -g root "$tmp" "$target"
  rm -f "$tmp"
  log_info "installed sudoers drop-in '$name'"
}

# install_root_helper <path> <content>
# Writes a script to <path> as root with mode 755. Skips if unchanged.
install_root_helper() {
  local path="$1"
  local content="$2"
  local tmp
  tmp=$(mktemp)
  printf '%s' "$content" >"$tmp"
  if sudo test -f "$path" && sudo cmp -s "$tmp" "$path"; then
    log_debug "root helper $path already up to date"
    rm -f "$tmp"
    return 0
  fi
  sudo install -m 755 -o root -g root "$tmp" "$path"
  rm -f "$tmp"
  log_info "installed root helper $path"
}

# install_user_helper <path> <content>
# Writes a user-owned script to <path> with mode 755. Skips if unchanged.
# Replaces any existing symlink at the target.
install_user_helper() {
  local path="$1"
  local content="$2"
  local dir
  dir=$(dirname "$path")
  mkdir -p "$dir"
  local tmp
  tmp=$(mktemp)
  printf '%s' "$content" >"$tmp"
  if [[ -f "$path" && ! -L "$path" ]] && cmp -s "$tmp" "$path"; then
    log_debug "user helper $path already up to date"
    rm -f "$tmp"
    return 0
  fi
  rm -f "$path"
  install -m 755 "$tmp" "$path"
  rm -f "$tmp"
  log_info "installed user helper $path"
}

# install_user_unit <unit_filename> <content>
# Writes/updates ~/.config/systemd/user/<unit_filename> and reloads daemon if changed.
install_user_unit() {
  local name="$1"
  local content="$2"
  local dir="$HOME/.config/systemd/user"
  local target="$dir/$name"
  mkdir -p "$dir"
  local tmp
  tmp=$(mktemp)
  printf '%s' "$content" >"$tmp"
  if [[ -f "$target" ]] && cmp -s "$tmp" "$target"; then
    log_debug "user unit $name already up to date"
    rm -f "$tmp"
    return 0
  fi
  install -m 644 "$tmp" "$target"
  rm -f "$tmp"
  log_info "installed user unit $name"
  systemctl --user daemon-reload || true
}

# enable_user_unit <unit_filename>
enable_user_unit() {
  local name="$1"
  if systemctl --user is-enabled --quiet "$name" 2>/dev/null; then
    log_debug "user unit $name already enabled"
    return 0
  fi
  systemctl --user enable "$name"
  log_info "enabled user unit $name"
}

# enable_system_unit <unit_filename>
# Warns and continues when systemd isn't running (containers, chroots) so
# installers don't abort the whole bootstrap on environments without an init.
enable_system_unit() {
  local name="$1"
  if ! command -v systemctl >/dev/null 2>&1 || [[ ! -d /run/systemd/system ]]; then
    log_warn "systemd not running; skipping enable of $name"
    return 0
  fi
  if systemctl is-enabled --quiet "$name" 2>/dev/null; then
    log_debug "system unit $name already enabled"
    return 0
  fi
  if ! sudo systemctl enable --now "$name"; then
    log_warn "could not enable $name (continuing)"
    return 0
  fi
  log_info "enabled system unit $name"
}

# add_user_to_group <group>
# Idempotent. Group membership change takes effect at next login.
add_user_to_group() {
  local group="$1"
  if id -nG "$USER" | tr ' ' '\n' | grep -qx "$group"; then
    log_debug "user $USER already in group $group"
    return 0
  fi
  sudo usermod -aG "$group" "$USER"
  log_info "added $USER to group $group (effective next login)"
}
