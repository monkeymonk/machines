#!/usr/bin/env bash
set -euo pipefail

# sunsetr (https://github.com/psi4j/sunsetr) — Wayland blue light filter with
# preset/schedule support. Standalone installer; not wired into niri-stack.
#
# Installs the AUR `sunsetr-bin` package plus:
#   - ~/.config/sunsetr/schedule.conf
#   - ~/.config/sunsetr/presets/{0700-day,2100-dusk,2300-night}/sunsetr.toml
#   - ~/.local/bin/sunsetr-set    (wrapper used by the Noctalia NSunsetr plugin;
#                                  not shipped upstream)
#
# Note: sunsetr.toml itself is created by sunsetr on first launch and is not
# managed here — geolocation must be initialised once with `sunsetr geo`.
#
# Post-install (manual):
#   1. sunsetr geo                                  # sets latitude/longitude
#   2. Add to ~/.config/niri/config.kdl, near the top:
#        spawn-at-startup "sunsetr"
#   3. For the Noctalia NSunsetr plugin
#      (https://github.com/kenanpelit/noctalia-nplugins/tree/main/nsunsetr):
#      install the plugin, then restart Noctalia:
#        qs -c noctalia-shell quit && noctalia-shell

_SUNSETR_CFG_DIR="$HOME/.config/sunsetr"
_SUNSETR_SCHEDULE="$_SUNSETR_CFG_DIR/schedule.conf"
_SUNSETR_PRESETS_DIR="$_SUNSETR_CFG_DIR/presets"
_SUNSETR_SET_BIN="$HOME/.local/bin/sunsetr-set"

_sunsetr_write_schedule() {
  mkdir -p "$_SUNSETR_CFG_DIR"
  if [[ -f "$_SUNSETR_SCHEDULE" ]]; then
    log_debug "sunsetr schedule.conf already present"
    return 0
  fi
  cat > "$_SUNSETR_SCHEDULE" <<'EOF'
07:00 0700-day
21:00 2100-dusk
23:00 2300-night
EOF
  log_info "wrote sunsetr schedule.conf"
}

_sunsetr_write_preset() {
  local name="$1"
  local temp="$2"
  local gamma="$3"
  local dir="$_SUNSETR_PRESETS_DIR/$name"
  local target="$dir/sunsetr.toml"
  mkdir -p "$dir"
  if [[ -f "$target" ]]; then
    log_debug "sunsetr preset $name already present"
    return 0
  fi
  cat > "$target" <<EOF
backend = "auto"
transition_mode = "static"
static_temp = $temp
static_gamma = $gamma
EOF
  log_info "wrote sunsetr preset $name"
}

_sunsetr_install_set_helper() {
  local content
  content=$(cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

preset="${1:-}"
[[ -n "$preset" ]] || exit 2

case "$preset" in
  auto)
    now="$(date +%H%M)"
    selected="default"
    while read -r time name; do
      [[ "$time" =~ ^[0-9]{2}:[0-9]{2}$ ]] || continue
      [[ "${time/:/}" -le "$now" ]] && selected="$name"
    done < "${XDG_CONFIG_HOME:-$HOME/.config}/sunsetr/schedule.conf"
    exec sunsetr preset "$selected"
    ;;
  default)
    exec sunsetr preset default
    ;;
  *)
    exec sunsetr preset "$preset"
    ;;
esac
EOF
)
  install_user_helper "$_SUNSETR_SET_BIN" "$content"
}

install_sunsetr() {
  if ! is_display_host; then
    log_info "skipping sunsetr (not a display host)"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install sunsetr (sunsetr-bin + presets + sunsetr-set helper)"
    return 0
  fi
  if ! is_arch; then
    log_warn "sunsetr only auto-installed on Arch-family (AUR); skipping on $DISTRO"
    return 1
  fi

  # sunsetr, sunsetr-bin and sunsetr-git all conflict with each other. Honour
  # whichever variant is already installed instead of forcing sunsetr-bin.
  if command_exists sunsetr; then
    log_info "sunsetr already installed"
  else
    aur_install sunsetr-bin
  fi
  ensure_command jq jq

  _sunsetr_write_schedule
  _sunsetr_write_preset 0700-day   6500 100
  _sunsetr_write_preset 2100-dusk  4000 95
  _sunsetr_write_preset 2300-night 3300 90
  _sunsetr_install_set_helper

  log_info "sunsetr installed — run 'sunsetr geo' once and add 'spawn-at-startup \"sunsetr\"' to ~/.config/niri/config.kdl"
}

install_sunsetr
