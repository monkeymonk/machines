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
        pkg_install docker-compose-plugin
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
    if ! systemctl is-active --quiet docker; then
      sudo systemctl enable --now docker
    fi
  fi
}

install_docker
