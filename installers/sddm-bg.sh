#!/usr/bin/env bash
set -euo pipefail

# SDDM background rotator: picks a random wallpaper from ~/Pictures/wallpapers
# at each login and copies it into the sugar-candy theme via a privileged
# helper. Wires up the privileged helper, sudoers rule, theme overrides, the
# user-side rotator script in ~/.local/bin/, and a user systemd unit.

_SDDM_THEMES="/usr/share/sddm/themes/sugar-candy"
_SDDM_THEME_CONF="/etc/sddm.conf.d/theme.conf"
_SDDM_THEME_USER_CONF="$_SDDM_THEMES/theme.conf.user"
_SDDM_HELPER="/usr/local/bin/set-sddm-bg"
_SDDM_SUDOERS="sddm-bg"
_SDDM_USER_UNIT="update-sddm-bg.service"
_SDDM_USER_SCRIPT="$HOME/.local/bin/update-sddm-bg"

_sddm_bg_set_theme_current() {
  local content="[Theme]
Current=sugar-candy
"
  if sudo test -f "$_SDDM_THEME_CONF" && sudo grep -q '^Current=sugar-candy' "$_SDDM_THEME_CONF"; then
    log_debug "sddm theme already set to sugar-candy"
    return 0
  fi
  sudo install -d /etc/sddm.conf.d
  echo "$content" | sudo tee "$_SDDM_THEME_CONF" >/dev/null
  log_info "set sddm Current=sugar-candy"
}

_sddm_bg_write_theme_user_conf() {
  local content="[General]
Background=\"Backgrounds/current.jpg\"
DimBackgroundImage=\"0.20\"
ScaleImageCropped=\"true\"
ForceHideCompletePassword=\"true\"
"
  if sudo test -f "$_SDDM_THEME_USER_CONF"; then
    if sudo cmp -s <(printf '%s' "$content") "$_SDDM_THEME_USER_CONF"; then
      log_debug "sugar-candy theme.conf.user already up to date"
      return 0
    fi
  fi
  echo "$content" | sudo tee "$_SDDM_THEME_USER_CONF" >/dev/null
  log_info "wrote sugar-candy theme.conf.user"
}

_sddm_bg_install_helper() {
  local content='#!/usr/bin/env bash
set -euo pipefail
src="$1"
dst="/usr/share/sddm/themes/sugar-candy/Backgrounds/current.jpg"
install -Dm644 "$src" "$dst"
'
  install_root_helper "$_SDDM_HELPER" "$content"
}

_sddm_bg_install_sudoers() {
  local rule="${USER} ALL=(root) NOPASSWD: ${_SDDM_HELPER}"
  install_sudoers_drop_in "$_SDDM_SUDOERS" "$rule"
}

_sddm_bg_install_user_script() {
  local content='#!/usr/bin/env bash
set -euo pipefail

mapfile -d '"'"''"'"' files < <(
  find "$HOME/Pictures/wallpapers" -type f \( \
    -iname '"'"'*.jpg'"'"' -o -iname '"'"'*.jpeg'"'"' -o -iname '"'"'*.png'"'"' -o -iname '"'"'*.webp'"'"' \) -print0
)

(( ${#files[@]} )) || exit 1

picked="${files[RANDOM % ${#files[@]}]}"

sudo -n /usr/local/bin/set-sddm-bg "$picked"
'
  install_user_helper "$_SDDM_USER_SCRIPT" "$content"
}

_sddm_bg_install_user_unit() {
  local content='[Unit]
Description=Update SDDM background after login

[Service]
Type=oneshot
ExecStart=%h/.local/bin/update-sddm-bg

[Install]
WantedBy=default.target
'
  install_user_unit "$_SDDM_USER_UNIT" "$content"
  enable_user_unit "$_SDDM_USER_UNIT"
}

install_sddm_bg() {
  if ! is_display_host; then
    log_info "skipping sddm-bg setup (not a display host)"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install sddm-bg (theme conf, helper, sudoers, user unit)"
    return 0
  fi

  install_sugar_candy_theme

  _sddm_bg_set_theme_current
  _sddm_bg_write_theme_user_conf
  _sddm_bg_install_helper
  _sddm_bg_install_sudoers
  _sddm_bg_install_user_script
  _sddm_bg_install_user_unit
}

# Source sugar-candy installer to get install_sugar_candy_theme.
# shellcheck source=./sugar-candy.sh
source "$(dirname "${BASH_SOURCE[0]}")/sugar-candy.sh"

install_sddm_bg
