#!/usr/bin/env bash
set -euo pipefail

# Docker Sandboxes CLI (sbx). Installs AND updates on every run:
#   - Arch: AUR package docker-sbx via paru -S --needed (upgrades in place).
#   - Debian/Ubuntu: Docker's official apt repo, package docker-sbx (apt
#     install on an already-installed package upgrades it).
#   - macOS: brew install/upgrade docker/tap/sbx.
# Docker itself is not required for sbx to run.
# Returns success if the resolved binary at $1 is owned by the system
# package manager (pacman/dpkg) or lives under the Homebrew prefix. Used to
# tell a package-managed sbx apart from a stray binary left on PATH by an
# older manual install.
_sbx_pkg_owned() {
  local path="$1"
  if is_arch; then
    pacman -Qo "$path" >/dev/null 2>&1
  elif is_debian_like; then
    dpkg -S "$path" >/dev/null 2>&1
  elif is_macos; then
    local brew_prefix
    brew_prefix="$(brew --prefix 2>/dev/null)"
    [[ -n "$brew_prefix" && "$path" == "$brew_prefix"/* ]]
  else
    return 1
  fi
}

install_sbx() {
  local dry_run="${DRY_RUN:-false}"

  if command_exists sbx; then
    log_info "sbx currently installed: $(sbx version 2>/dev/null | head -1)"
  fi

  if [[ "$dry_run" == true ]]; then
    if is_arch; then
      log_info "Would bootstrap paru and install/update docker-sbx via AUR (dry-run)"
    elif is_debian_like; then
      log_info "Would register Docker's apt repo and install/update docker-sbx via apt (dry-run)"
    elif is_macos; then
      log_info "Would install/update sbx via 'brew install/upgrade docker/tap/sbx' (dry-run)"
    else
      log_info "sbx is not supported on this platform (dry-run)"
    fi
    return 0
  fi

  if is_arch; then
    log_info "Installing/updating docker-sbx via AUR"
    aur_bootstrap_paru
    paru -S --needed --noconfirm docker-sbx
  elif is_debian_like; then
    log_info "Installing/updating docker-sbx via Docker's apt repo"
    local distro_path="debian"
    if [[ "$IS_UBUNTU" == true ]]; then
      distro_path="ubuntu"
    fi
    apt_repo_add docker \
      "https://download.docker.com/linux/${distro_path}/gpg" \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro_path} $(os_codename) stable"
    sudo apt-get update
    sudo apt-get install -y docker-sbx
  elif is_macos; then
    if ! command_exists brew; then
      log_error "Homebrew not available; cannot install sbx"
      return 1
    fi
    brew trust docker/tap || true
    if brew list docker/tap/sbx >/dev/null 2>&1; then
      log_info "Updating sbx via brew"
      brew upgrade docker/tap/sbx || log_info "brew upgrade docker/tap/sbx reported nothing to do (likely already latest)"
    else
      log_info "Installing sbx via brew"
      brew install docker/tap/sbx
    fi
  else
    log_error "sbx is not supported on this platform ($DISTRO)"
    return 1
  fi

  if [[ "$IS_LINUX" == true ]]; then
    if getent group kvm >/dev/null 2>&1; then
      add_user_to_group kvm
    fi
    if ! lsmod | grep kvm >/dev/null; then
      log_warn "no kvm kernel module loaded; local sbx sandboxes need KVM"
    fi
  fi

  if command_exists sbx; then
    local -a raw_paths owned_paths=()
    mapfile -t raw_paths < <(type -ap sbx)
    local p resolved
    for p in "${raw_paths[@]}"; do
      resolved="$(readlink -f "$p")"
      if _sbx_pkg_owned "$p" || _sbx_pkg_owned "$resolved"; then
        owned_paths+=("$p")
      fi
    done

    if [[ "${#owned_paths[@]}" -gt 0 ]]; then
      local moved=false
      for p in "${raw_paths[@]}"; do
        resolved="$(readlink -f "$p")"
        if _sbx_pkg_owned "$p" || _sbx_pkg_owned "$resolved"; then
          continue
        fi
        local backup="${p}.bak"
        if [[ -e "$backup" ]]; then
          backup="${p}.bak.$(date +%Y%m%d%H%M%S)"
        fi
        if [[ -w "$(dirname "$p")" ]]; then
          mv "$p" "$backup"
        else
          sudo mv "$p" "$backup"
        fi
        log_warn "moved stray sbx binary not owned by the package manager: $p -> $backup"
        moved=true
      done
      [[ "$moved" == true ]] && hash -r
    fi

    log_info "sbx installed: $(sbx version 2>/dev/null | head -1)"
    log_info "Run 'sbx login' once if you haven't signed in yet"
  fi
}

install_sbx
