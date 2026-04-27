#!/usr/bin/env bash
set -euo pipefail

install_docker() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists docker; then
    log_info "Docker already installed"
  else
    log_info "Installing Docker"
    if [[ "$dry_run" == true ]]; then
      log_info "Would install Docker and Docker Compose (dry-run)"
    else
      if is_macos; then
        if ! command_exists brew; then
          log_error "Homebrew not available; cannot install Docker"
          return 1
        fi
        brew install --cask docker
      elif is_debian_like; then
        pkg_install docker.io
        # Debian default repos ship docker-compose v1 (Python). Ubuntu noble
        # has docker-compose-v2 in universe. Try v2 first, fall back to v1,
        # warn if neither is available.
        if apt-cache show docker-compose-v2 >/dev/null 2>&1; then
          pkg_install docker-compose-v2
        elif apt-cache show docker-compose >/dev/null 2>&1; then
          pkg_install docker-compose
        else
          log_warn "no docker-compose package found in apt; install Docker official repo for docker-compose-plugin"
        fi
      elif is_arch; then
        pkg_install docker
        pkg_install docker-compose
      else
        pkg_install docker
        pkg_install docker-compose
      fi
    fi
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would enable Docker service (dry-run)"
    return 0
  fi

  if command_exists systemctl; then
    enable_system_unit docker.service
  fi

  if command_exists docker; then
    add_user_to_group docker
  fi
}

install_docker
