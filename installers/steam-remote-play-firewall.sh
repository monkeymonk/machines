#!/usr/bin/env bash
set -euo pipefail

# Open the UFW ports Steam Remote Play / Steam Link and VR streaming need for
# inbound headset and controller traffic. Without these, a locked-down UFW
# silently drops the Quest's packets and the PC shows up greyed-out in Steam
# Link (see Valve's Remote Play network guide).
#
# Ports (Valve):
#   UDP 27031, 27036          Remote Play discovery + streaming
#   TCP 27036, 27037          Remote Play
#   UDP 10400, 10401          VR streaming (Steam Link → SteamVR)
#
# Policy:
#   * Only touches UFW if it's already installed. We never install or enable a
#     firewall from here — a box without UFW has nothing blocking these ports,
#     and the gaming role deliberately doesn't pull in the security stack.
#   * Rules are scoped to the LAN subnet (any interface), never opened globally.
#   * `ufw allow` is idempotent — UFW skips duplicates — so re-runs are safe.
#   * The subnet is auto-detected from the default-route interface; override
#     with STEAM_LAN_SUBNET (e.g. "192.168.128.0/23") when detection is wrong
#     or the box has multiple NICs.

STEAM_REMOTE_PLAY_UDP_PORTS=(27031 27036 10400 10401)
STEAM_REMOTE_PLAY_TCP_PORTS=(27036 27037)

# Convert an IPv4 address + prefix to its network address in CIDR form.
# e.g. 192.168.129.9 23 -> 192.168.128.0/23
_ipv4_network() {
  local ip="$1" prefix="$2"
  local IFS=. o1 o2 o3 o4
  read -r o1 o2 o3 o4 <<<"$ip"
  local ip_int=$(((o1 << 24) | (o2 << 16) | (o3 << 8) | o4))
  local mask=0
  if ((prefix > 0)); then
    mask=$(((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF))
  fi
  local net=$((ip_int & mask))
  printf '%d.%d.%d.%d/%d\n' \
    $(((net >> 24) & 255)) $(((net >> 16) & 255)) $(((net >> 8) & 255)) $((net & 255)) "$prefix"
}

# True for RFC1918 / link-local ranges. Guards against opening ports to a public
# subnet if auto-detection ever picks up a non-LAN interface.
_is_private_subnet() {
  case "$1" in
  10.* | 192.168.* | 169.254.*) return 0 ;;
  172.1[6-9].* | 172.2[0-9].* | 172.3[0-1].*) return 0 ;;
  *) return 1 ;;
  esac
}

# Echo the LAN subnet in CIDR form, or empty on failure.
_detect_lan_subnet() {
  if [[ -n "${STEAM_LAN_SUBNET:-}" ]]; then
    echo "$STEAM_LAN_SUBNET"
    return 0
  fi
  command_exists ip || return 0
  local ifc ip_cidr ip prefix
  ifc=$(ip -4 route show default 2>/dev/null | awk '/default/ {print $5; exit}')
  [[ -z "$ifc" ]] && return 0
  ip_cidr=$(ip -o -4 addr show dev "$ifc" scope global 2>/dev/null | awk '{print $4; exit}')
  [[ -z "$ip_cidr" ]] && return 0
  ip="${ip_cidr%/*}"
  prefix="${ip_cidr#*/}"
  [[ "$ip" == "$prefix" ]] && return 0 # no prefix present
  _ipv4_network "$ip" "$prefix"
}

install_steam_remote_play_firewall() {
  local dry_run="${DRY_RUN:-false}"

  if ! command_exists ufw; then
    log_info "ufw not installed; Steam Remote Play/VR ports are unblocked already, nothing to do"
    return 0
  fi

  local subnet
  subnet=$(_detect_lan_subnet)
  if [[ -z "$subnet" ]]; then
    log_warn "Could not determine LAN subnet; set STEAM_LAN_SUBNET (e.g. 192.168.128.0/23) and re-run"
    return 0
  fi
  if ! _is_private_subnet "$subnet"; then
    log_warn "Detected subnet $subnet is not a private LAN range; refusing to open ports. Set STEAM_LAN_SUBNET explicitly."
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would add ufw allow rules for Steam Remote Play/VR ports from $subnet (dry-run)"
    return 0
  fi

  log_info "Opening Steam Remote Play/VR ports for LAN subnet $subnet"
  local port
  for port in "${STEAM_REMOTE_PLAY_UDP_PORTS[@]}"; do
    sudo ufw allow in from "$subnet" to any port "$port" proto udp
  done
  for port in "${STEAM_REMOTE_PLAY_TCP_PORTS[@]}"; do
    sudo ufw allow in from "$subnet" to any port "$port" proto tcp
  done
  log_info "Steam Remote Play/VR ports opened (UDP 27031/27036/10400/10401, TCP 27036/27037)"
}

install_steam_remote_play_firewall
