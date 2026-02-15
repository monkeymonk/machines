#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$SCRIPT_DIR"
export REPO_ROOT
LOG_LEVEL=${LOG_LEVEL:-info}

source_if_exists() {
  local path="$1"
  if [[ -f "$path" ]]; then
    # shellcheck disable=SC1090
    source "$path"
  fi
}

source_if_exists "$SCRIPT_DIR/lib/log.sh"
source_if_exists "$SCRIPT_DIR/lib/os.sh"
source_if_exists "$SCRIPT_DIR/lib/pkg.sh"
source_if_exists "$SCRIPT_DIR/packages/core.sh"
source_if_exists "$SCRIPT_DIR/packages/ai.sh"
source_if_exists "$SCRIPT_DIR/packages/dev.sh"
source_if_exists "$SCRIPT_DIR/packages/lazyvim.sh"
source_if_exists "$SCRIPT_DIR/packages/terminals.sh"
source_if_exists "$SCRIPT_DIR/packages/shell.sh"
source_if_exists "$SCRIPT_DIR/packages/security.sh"
source_if_exists "$SCRIPT_DIR/packages/server-tools.sh"
source_if_exists "$SCRIPT_DIR/packages/homelab.sh"
source_if_exists "$SCRIPT_DIR/roles/workstation.sh"
source_if_exists "$SCRIPT_DIR/roles/server.sh"
source_if_exists "$SCRIPT_DIR/roles/gaming.sh"
source_if_exists "$SCRIPT_DIR/roles/homelab.sh"
source_if_exists "$SCRIPT_DIR/bootstrap/arch.sh"
source_if_exists "$SCRIPT_DIR/bootstrap/ubuntu.sh"
source_if_exists "$SCRIPT_DIR/bootstrap/macos.sh"

AVAILABLE_ROLES=(server workstation gaming homelab)
ROLE="server"
DRY_RUN=false
EXTRA_PACKAGES=""
HOSTS_DIR="$SCRIPT_DIR/hosts"

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --role ROLE          Choose a role (default: server)
  --packages PKGS      Install additional packages (comma-separated)
  --dry-run            Show actions without installing
  -h|--help            Display this help message

Available roles:
  server               Minimal setup: core packages, shell, dev tools
  workstation          Full development: server + desktop apps, editors, AI tools
  gaming               Gaming-focused: core + desktop apps, Steam, nvidia drivers
  homelab              Server hardening + Docker + monitoring tools
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --role)
      if [[ -z "${2:-}" ]]; then
        log_error "--role requires a value"
        usage
        exit 1
      fi
      ROLE="$2"
      shift 2
      ;;
    --packages)
      if [[ -z "${2:-}" ]]; then
        log_error "--packages requires a value"
        usage
        exit 1
      fi
      EXTRA_PACKAGES="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      log_warn "Unknown option: $1" && usage
      exit 1
      ;;
    esac
  done
  local valid=false
  for candidate in "${AVAILABLE_ROLES[@]}"; do
    [[ "$candidate" == "$ROLE" ]] && valid=true && break
  done
  if [[ "$valid" != true ]]; then
    log_error "Role must be one of: ${AVAILABLE_ROLES[*]}"
    usage
    exit 1
  fi
}

run_bootstrap_hook() {
  case "$DISTRO" in
  arch)
    bootstrap_arch
    ;;
  ubuntu)
    bootstrap_ubuntu
    ;;
  macos)
    bootstrap_macos
    ;;
  *)
    log_warn "No bootstrap hooks for $DISTRO"
    ;;
  esac
}

run_role() {
  case "$ROLE" in
  server)
    server_role
    ;;
  workstation)
    workstation_role
    ;;
  gaming)
    gaming_role
    ;;
  homelab)
    homelab_role
    ;;
  *)
    log_error "Unknown role: $ROLE"
    exit 1
    ;;
  esac
}

install_extra_packages() {
  if [[ -z "$EXTRA_PACKAGES" ]]; then
    return 0
  fi
  log_info "Installing extra packages: $EXTRA_PACKAGES"
  local IFS=','
  read -r -a packages <<<"$EXTRA_PACKAGES"
  for pkg in "${packages[@]}"; do
    # Trim whitespace
    pkg="${pkg#"${pkg%%[![:space:]]*}"}"
    pkg="${pkg%"${pkg##*[![:space:]]}"}"
    if [[ -n "$pkg" ]]; then
      install_package "$pkg"
    fi
  done
}

run_host_overrides() {
  local hostname
  hostname=$(hostname)
  local host_file="$HOSTS_DIR/${hostname}.sh"

  if [[ -f "$host_file" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log_info "Would run host-specific overrides for $hostname (dry-run)"
    else
      log_info "Running host-specific overrides for $hostname"
      # shellcheck disable=SC1090
      source "$host_file"
    fi
  else
    log_debug "No host-specific overrides found for $hostname"
  fi
}

main() {
  parse_args "$@"
  log_info "Starting bootstrap for $DISTRO"
  ensure_supported_distro
  run_bootstrap_hook
  pkg_update
  install_core_packages
  run_role
  install_extra_packages
  run_host_overrides
  if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry-run mode enabled; no packages were changed"
  else
    log_info "Bootstrap completed for role $ROLE"
  fi
}

main "$@"
