#!/usr/bin/env bash
set -euo pipefail

# monique (https://github.com/ToRvaLDz/monique) — graphical monitor profile
# manager for Hyprland/Sway/Niri, with a daemon (`moniqued`) that watches for
# hotplug events and applies the active profile.
#
# Installs the AUR `monique` package and drops the Noctalia plugin
# (https://noctalia.dev/plugins/monique) into the user plugin directory so it
# can be enabled from the Noctalia settings panel.
#
# Plugin files come from the official registry repo:
#   https://github.com/noctalia-dev/noctalia-plugins (monique/ subdir)
# They are placed at ~/.config/noctalia/plugins/monique/ — the location
# Noctalia 4+ scans for user plugins.
#
# Post-install (manual):
#   1. Add to ~/.config/niri/config.kdl, near the top:
#        spawn-at-startup "moniqued"
#   2. Restart Noctalia so the new plugin is picked up:
#        qs -c noctalia-shell quit && noctalia-shell
#   3. Enable the plugin from Noctalia settings (if not already enabled in
#      ~/.config/noctalia/plugins.json).

_MONIQUE_PLUGINS_REPO="https://github.com/noctalia-dev/noctalia-plugins.git"
_MONIQUE_PLUGIN_SUBDIR="monique"
_MONIQUE_PLUGIN_DEST="$HOME/.config/noctalia/plugins/monique"

_monique_sync_plugin() {
  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN

  git clone --depth=1 --filter=blob:none --sparse \
    "$_MONIQUE_PLUGINS_REPO" "$tmp/repo" >/dev/null
  git -C "$tmp/repo" sparse-checkout set "$_MONIQUE_PLUGIN_SUBDIR" >/dev/null

  local src="$tmp/repo/$_MONIQUE_PLUGIN_SUBDIR"
  if [[ ! -f "$src/manifest.json" ]]; then
    log_warn "monique plugin not found in $_MONIQUE_PLUGINS_REPO ($_MONIQUE_PLUGIN_SUBDIR)"
    return 1
  fi

  mkdir -p "$(dirname "$_MONIQUE_PLUGIN_DEST")"
  rm -rf "$_MONIQUE_PLUGIN_DEST"
  cp -a "$src" "$_MONIQUE_PLUGIN_DEST"
  log_info "installed Noctalia monique plugin -> $_MONIQUE_PLUGIN_DEST"
}

install_monique() {
  if ! is_display_host; then
    log_info "skipping monique (not a display host)"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_info "Would install monique (AUR monique + Noctalia plugin)"
    return 0
  fi
  if ! is_arch; then
    log_warn "monique only auto-installed on Arch-family (AUR); skipping on $DISTRO"
    return 1
  fi

  if command_exists monique; then
    log_info "monique already installed"
  else
    aur_install monique
  fi

  _monique_sync_plugin

  log_info "monique installed — add 'spawn-at-startup \"moniqued\"' to ~/.config/niri/config.kdl and restart noctalia-shell"
}

install_monique
