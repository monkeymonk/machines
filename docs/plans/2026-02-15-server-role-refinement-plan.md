# Server Role Refinement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor server role to be lean and secure, create homelab role extension

**Architecture:** Create new package groups (security, server-tools, homelab), new installers (fail2ban, ufw), update server role to remove zsh/vim, create homelab role that extends server

**Tech Stack:** Bash, distro package managers (apt/pacman/brew), systemd

---

## Task 1: Create security package group

**Files:**
- Create: `packages/security.sh`

**Step 1: Write security package group**

Create `packages/security.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Security and compliance packages
SECURITY_PACKAGES=(
  openssh-server
  auditd
  logwatch
)

# Debian-specific security packages
DEBIAN_SECURITY_PACKAGES=(
  unattended-upgrades
  apt-listchanges
)

install_security_packages() {
  # Install fail2ban via custom installer
  install_package fail2ban

  # Install ufw via custom installer
  install_package ufw

  # Install common security packages
  for pkg in "${SECURITY_PACKAGES[@]}"; do
    install_package "$pkg"
  done

  # Install Debian-specific packages
  if is_debian_like; then
    for pkg in "${DEBIAN_SECURITY_PACKAGES[@]}"; do
      install_package "$pkg"
    done
  fi
}
```

**Step 2: Lint the file**

Run: `shellcheck packages/security.sh`
Expected: No errors

**Step 3: Commit**

```bash
git add packages/security.sh
git commit -m "Add security package group"
```

---

## Task 2: Create server-tools package group

**Files:**
- Create: `packages/server-tools.sh`

**Step 1: Write server-tools package group**

Create `packages/server-tools.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Server management utilities
SERVER_TOOLS_PACKAGES=(
  ncdu
  rsync
  bash-completion
)

install_server_tools() {
  install_packages "${SERVER_TOOLS_PACKAGES[@]}"
}
```

**Step 2: Lint the file**

Run: `shellcheck packages/server-tools.sh`
Expected: No errors

**Step 3: Commit**

```bash
git add packages/server-tools.sh
git commit -m "Add server-tools package group"
```

---

## Task 3: Create homelab package group

**Files:**
- Create: `packages/homelab.sh`

**Step 1: Write homelab package group**

Create `packages/homelab.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Homelab-specific networking and secrets tools
HOMELAB_PACKAGES=(
  net-tools
  iproute2
  sops
)

install_homelab_packages() {
  install_packages "${HOMELAB_PACKAGES[@]}"
  # age is already in core.sh, no need to reinstall
}
```

**Step 2: Lint the file**

Run: `shellcheck packages/homelab.sh`
Expected: No errors

**Step 3: Commit**

```bash
git add packages/homelab.sh
git commit -m "Add homelab package group"
```

---

## Task 4: Create fail2ban installer

**Files:**
- Create: `installers/fail2ban.sh`

**Step 1: Write fail2ban installer**

Create `installers/fail2ban.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

install_fail2ban() {
  local dry_run="${DRY_RUN:-false}"

  # Check if already installed
  if command_exists fail2ban-server; then
    log_info "fail2ban already installed"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install fail2ban (dry-run)"
    return 0
  fi

  log_info "Installing fail2ban"

  # Install package (distro-aware)
  if is_debian_like; then
    pkg_install fail2ban
  elif is_arch; then
    pkg_install fail2ban
  elif is_macos; then
    log_warn "fail2ban not available on macOS, skipping"
    return 0
  else
    log_error "Unsupported distro for fail2ban"
    return 1
  fi

  # Enable and start service
  if command_exists systemctl; then
    if ! systemctl is-active --quiet fail2ban 2>/dev/null; then
      log_info "Enabling and starting fail2ban service"
      sudo systemctl enable fail2ban
      sudo systemctl start fail2ban
    fi
  fi
}

install_fail2ban
```

**Step 2: Lint the file**

Run: `shellcheck installers/fail2ban.sh`
Expected: No errors

**Step 3: Test dry-run mode**

Run: `DRY_RUN=true bash installers/fail2ban.sh`
Expected: Log message "Would install fail2ban (dry-run)"

**Step 4: Commit**

```bash
git add installers/fail2ban.sh
git commit -m "Add fail2ban installer with systemd service management"
```

---

## Task 5: Create ufw installer

**Files:**
- Create: `installers/ufw.sh`

**Step 1: Write ufw installer**

Create `installers/ufw.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

install_ufw() {
  local dry_run="${DRY_RUN:-false}"

  # Check if already installed and configured
  if command_exists ufw; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
      log_info "ufw already installed and configured"
      return 0
    fi
  fi

  if [[ "$dry_run" == true ]]; then
    log_info "Would install and configure ufw (dry-run)"
    return 0
  fi

  # Install if needed
  if ! command_exists ufw; then
    log_info "Installing ufw"
    if is_debian_like; then
      pkg_install ufw
    elif is_arch; then
      pkg_install ufw
    elif is_macos; then
      log_warn "ufw not available on macOS, skipping"
      return 0
    else
      log_error "Unsupported distro for ufw"
      return 1
    fi
  fi

  # Configure firewall
  log_info "Configuring ufw firewall"
  sudo ufw --force reset
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw limit ssh

  # Enable non-interactively
  log_info "Enabling ufw"
  echo "y" | sudo ufw enable

  log_info "UFW configured: deny incoming, allow outgoing, rate-limit SSH"
}

install_ufw
```

**Step 2: Lint the file**

Run: `shellcheck installers/ufw.sh`
Expected: No errors

**Step 3: Test dry-run mode**

Run: `DRY_RUN=true bash installers/ufw.sh`
Expected: Log message "Would install and configure ufw (dry-run)"

**Step 4: Commit**

```bash
git add installers/ufw.sh
git commit -m "Add ufw installer with firewall configuration"
```

---

## Task 6: Update server role

**Files:**
- Modify: `roles/server.sh`

**Step 1: Update server role to use new packages**

Modify `roles/server.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Lean server role focused on security and essentials
server_role() {
  install_core_packages
  install_security_packages
  install_server_tools
  install_package docker
  install_package neovim
}
```

**Step 2: Lint the file**

Run: `shellcheck roles/server.sh`
Expected: No errors

**Step 3: Test dry-run**

Run: `./install.sh --role server --dry-run`
Expected: No errors, shows what would be installed

**Step 4: Commit**

```bash
git add roles/server.sh
git commit -m "Refactor server role to remove zsh and add security packages"
```

---

## Task 7: Create homelab role

**Files:**
- Create: `roles/homelab.sh`

**Step 1: Write homelab role**

Create `roles/homelab.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Homelab role extends server with additional networking/secrets tools
homelab_role() {
  # Run full server setup
  server_role

  # Add homelab-specific packages
  install_homelab_packages
}
```

**Step 2: Lint the file**

Run: `shellcheck roles/homelab.sh`
Expected: No errors

**Step 3: Test dry-run**

Run: `./install.sh --role homelab --dry-run`
Expected: No errors, shows server + homelab packages

**Step 4: Commit**

```bash
git add roles/homelab.sh
git commit -m "Add homelab role extending server with networking tools"
```

---

## Task 8: Update dev packages

**Files:**
- Modify: `packages/dev.sh`

**Step 1: Remove vim from dev packages**

Modify `packages/dev.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Additional tooling useful for development systems.
# Note: htop and jq are in core.sh, kept here for explicit dev role
DEV_PACKAGES=(htop jq)

install_dev_packages() {
  install_packages "${DEV_PACKAGES[@]}"
}
```

**Step 2: Lint the file**

Run: `shellcheck packages/dev.sh`
Expected: No errors

**Step 3: Commit**

```bash
git add packages/dev.sh
git commit -m "Remove vim from dev packages"
```

---

## Task 9: Update main installer to source new packages

**Files:**
- Modify: `install.sh`

**Step 1: Add source statements for new packages**

Find the section in `install.sh` where packages are sourced (around line 30-50) and add:

```bash
[[ -f "${SCRIPT_DIR}/packages/security.sh" ]] && source "${SCRIPT_DIR}/packages/security.sh"
[[ -f "${SCRIPT_DIR}/packages/server-tools.sh" ]] && source "${SCRIPT_DIR}/packages/server-tools.sh"
[[ -f "${SCRIPT_DIR}/packages/homelab.sh" ]] && source "${SCRIPT_DIR}/packages/homelab.sh"
```

**Step 2: Verify install.sh syntax**

Run: `bash -n install.sh`
Expected: No errors

**Step 3: Lint the file**

Run: `shellcheck install.sh`
Expected: No errors (or existing warnings only)

**Step 4: Commit**

```bash
git add install.sh
git commit -m "Source new package groups in main installer"
```

---

## Task 10: Run full test suite

**Files:**
- Test: All new and modified files

**Step 1: Run shellcheck on all scripts**

Run: `shellcheck install.sh lib/*.sh packages/*.sh installers/*.sh roles/*.sh`
Expected: No errors

**Step 2: Run test suite**

Run: `./test.sh`
Expected: All tests pass

**Step 3: Test server role dry-run**

Run: `./install.sh --role server --dry-run`
Expected: Shows installation plan with security packages, no errors

**Step 4: Test homelab role dry-run**

Run: `./install.sh --role homelab --dry-run`
Expected: Shows server + homelab packages, no errors

**Step 5: Verify workstation role still works**

Run: `./install.sh --role workstation --dry-run`
Expected: No errors (should not be affected by changes)

---

## Task 11: Integration test on Ubuntu (Docker)

**Files:**
- Test: Docker-based quick test

**Step 1: Run Docker test for Ubuntu**

Run: `make test-quick`
Expected: Ubuntu test passes, server role installs successfully

**Step 2: Verify packages installed**

Check test output for:
- fail2ban installed
- ufw installed
- neovim installed
- No zsh/oh-my-zsh

**Step 3: Document results**

Create test report noting any issues or successes

---

## Task 12: Integration test on Debian (Docker)

**Files:**
- Test: Docker-based quick test

**Step 1: Run Docker test for Debian**

Run: `make test-debian12`
Expected: Debian test passes

**Step 2: Verify Debian-specific packages**

Check for:
- unattended-upgrades installed
- apt-listchanges installed

**Step 3: Document results**

---

## Task 13: Integration test on Arch (Docker)

**Files:**
- Test: Docker-based quick test

**Step 1: Run Docker test for Arch**

Run: `make test-arch`
Expected: Arch test passes

**Step 2: Verify Arch compatibility**

Check for:
- fail2ban installed via pacman
- ufw installed via pacman
- No Debian-specific packages attempted

**Step 3: Document results**

---

## Task 14: Final verification and cleanup

**Step 1: Review all commits**

Run: `git log --oneline | head -10`
Expected: See all implementation commits

**Step 2: Run full shellcheck**

Run: `shellcheck install.sh lib/*.sh packages/*.sh installers/*.sh roles/*.sh`
Expected: No new errors

**Step 3: Update CLAUDE.md if needed**

Review `CLAUDE.md` to ensure documentation reflects new roles/packages

**Step 4: Create final commit if needed**

```bash
git add CLAUDE.md
git commit -m "Update documentation for server role refinement"
```

---

## Testing Verification Checklist

After implementation, verify:

- [ ] Server role does NOT install zsh/oh-my-zsh
- [ ] Server role installs neovim (not vim)
- [ ] Server role installs fail2ban and starts service
- [ ] Server role installs ufw and configures firewall
- [ ] Server role installs security packages (openssh, auditd, logwatch)
- [ ] Server role installs server tools (ncdu, rsync, bash-completion)
- [ ] Homelab role includes all server packages
- [ ] Homelab role adds homelab packages (net-tools, iproute2, sops)
- [ ] Dry-run mode works for all roles
- [ ] Shellcheck passes on all scripts
- [ ] Ubuntu 24.04 integration test passes
- [ ] Debian 12 integration test passes
- [ ] Arch integration test passes

---

## Rollback Plan

If issues arise:

1. Revert commits: `git revert HEAD~N` (where N is number of commits)
2. Or reset branch: `git reset --hard <commit-before-changes>`
3. Test old server role still works
4. Debug issues in separate branch
