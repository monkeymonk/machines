#!/usr/bin/env bash
set -euo pipefail

# Distro detection, family flags, and capability gates so installers and
# packages can branch on what the box actually is.

detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    echo "${ID:-unknown}"
    return
  fi

  local uname
  uname=$(uname -s)
  case "$uname" in
  Linux) echo "linux" ;;
  Darwin) echo "macos" ;;
  *) echo "unknown" ;;
  esac
}

os_codename() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    echo "${VERSION_CODENAME:-${VERSION_ID:-}}"
  fi
}

IS_UBUNTU=false
IS_DEBIAN=false
IS_ARCH=false
IS_CACHYOS=false
IS_MANJARO=false
IS_ENDEAVOUROS=false
IS_MACOS=false
IS_LINUX=false
IS_WSL=false
IS_HEADLESS=false

DISTRO=$(detect_distro)

# IS_ARCH is set true for the whole arch family (vanilla arch, cachyos,
# manjaro, endeavouros). Existing installers that gate on `is_arch` will
# correctly use pacman on cachyos/etc. without needing per-call updates.
case "$DISTRO" in
ubuntu)      IS_UBUNTU=true;      IS_LINUX=true ;;
debian)      IS_DEBIAN=true;      IS_LINUX=true ;;
arch)        IS_ARCH=true;        IS_LINUX=true ;;
cachyos)     IS_ARCH=true;        IS_CACHYOS=true;     IS_LINUX=true ;;
manjaro)     IS_ARCH=true;        IS_MANJARO=true;     IS_LINUX=true ;;
endeavouros) IS_ARCH=true;        IS_ENDEAVOUROS=true; IS_LINUX=true ;;
macos)       IS_MACOS=true ;;
linux)       IS_LINUX=true ;;
*) ;;
esac

if [[ "$IS_LINUX" == true ]]; then
  if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    IS_WSL=true
  fi
fi

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
  IS_HEADLESS=true
fi

is_supported_distro() {
  [[ "$IS_UBUNTU" == true || "$IS_DEBIAN" == true || "$IS_ARCH" == true || "$IS_MACOS" == true ]]
}

is_debian_like() {
  [[ "$IS_UBUNTU" == true || "$IS_DEBIAN" == true ]]
}

is_arch() {
  [[ "$IS_ARCH" == true ]]
}

# Alias for clarity at call sites; identical to is_arch.
is_arch_family() {
  is_arch
}

is_cachyos() {
  [[ "$IS_CACHYOS" == true ]]
}

is_macos() {
  [[ "$IS_MACOS" == true ]]
}

is_wsl() {
  [[ "$IS_WSL" == true ]]
}

is_headless() {
  [[ "$IS_HEADLESS" == true ]]
}

# Capability gates — used by installers/packages instead of SKIP keywords.

# True when this user manages the local display directly: linux box, not WSL,
# not a headless server. Use for display managers, compositors, theme installs.
is_display_host() {
  [[ "$IS_LINUX" == true && "$IS_WSL" != true && "$IS_HEADLESS" != true ]]
}

# True when graphical apps can run. WSL with WSLg sets DISPLAY/WAYLAND_DISPLAY,
# so IS_HEADLESS is false → WSL workstations install GUI apps. Use for GUI apps
# (browsers, discord, bitwarden, file managers).
is_gui_capable() {
  [[ "$IS_HEADLESS" != true ]] || [[ "$IS_MACOS" == true ]]
}

ensure_supported_distro() {
  if ! is_supported_distro; then
    log_error "Unsupported distro: $DISTRO"
    return 1
  fi
}
