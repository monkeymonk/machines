# Server Role Refinement

## Motivation

Current `server` role is too heavy for production servers:
- Includes zsh/oh-my-zsh (unnecessary for headless servers)
- Uses vim instead of neovim
- Missing critical security tools (fail2ban, ufw, unattended-upgrades)
- Missing server utilities (ncdu, rsync)
- No homelab-specific tooling

## Goals

1. **Streamline server role** - Remove desktop/interactive tools, focus on essentials
2. **Security hardening** - Add fail2ban, ufw with sane defaults, audit tools
3. **Server utilities** - Add disk management, backup, monitoring tools
4. **Homelab extension** - Separate role for homelab-specific packages

## Architecture

### Package Groups

Create three new package groups in `packages/`:

**security.sh** - Security and compliance tools
- fail2ban (brute force protection)
- ufw (firewall with rate limiting)
- openssh-server
- unattended-upgrades (auto security updates)
- apt-listchanges (track package changes)
- auditd (security auditing)
- logwatch (log monitoring)

**server-tools.sh** - Server management utilities
- ncdu (disk usage analyzer)
- rsync (file synchronization)
- bash-completion (command completion)

**homelab.sh** - Homelab-specific packages
- net-tools (ifconfig, netstat)
- iproute2 (modern ip command)
- sops (secrets management)
- age (already in core, verify availability)

### Installers

Create two new installers in `installers/`:

**fail2ban.sh**
- Install fail2ban package
- Enable and start systemd service
- Use package default configuration (no custom jails)
- Idempotent: skip if already installed and running

**ufw.sh**
- Install ufw package
- Configure default policies: deny incoming, allow outgoing
- Add rate-limited SSH rule: `ufw limit ssh`
- Enable firewall non-interactively
- Idempotent: skip configuration if already active

### Role Updates

**roles/server.sh** - Streamlined for production
```bash
server_role() {
  install_core_packages      # git, curl, build tools, cargo packages, nvm
  install_security_packages  # fail2ban, ufw, openssh, unattended-upgrades
  install_server_tools       # ncdu, rsync, bash-completion
  install_package docker     # Docker CLI only (no daemon management)
  install_package neovim     # Replace vim
}
```

Removed:
- `install_shell_stack` (zsh/oh-my-zsh)
- `install_dev_packages` (vim, htop, jq already in core)

**roles/homelab.sh** - New role extending server
```bash
homelab_role() {
  server_role              # Full server setup
  install_homelab_packages # Networking and secrets tools
}
```

**packages/dev.sh** - Minimal update
- Keep htop, jq (though duplicated in core)
- Remove vim (replaced by neovim in server role)

## Implementation Details

### Distro Compatibility

**Debian/Ubuntu:**
- All packages available via apt
- apt-listchanges, unattended-upgrades are Debian-specific
- Use `is_debian_like` guard for these packages

**Arch:**
- fail2ban, ufw available via pacman
- No direct equivalent for unattended-upgrades (pacman has different update model)
- Use distro mapping: `"unattended-upgrades,arch:pacman"`

**macOS:**
- Skip fail2ban, ufw, openssh-server (not applicable)
- Use `is_macos` guard to skip security packages

### Security Configuration

**UFW Rules:**
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit ssh  # Rate limit: max 6 conn/30sec per IP
echo "y" | sudo ufw enable
```

**fail2ban:**
- Package default jails (SSH enabled by default on Debian/Ubuntu)
- No custom configuration (keeps bootstrap tool simple)
- Users can customize via dotfiles or hosts/ overrides

### Idempotence

All installers check before acting:
- fail2ban: `command_exists fail2ban-server`
- ufw: `command_exists ufw && sudo ufw status | grep "Status: active"`
- Packages: handled by `pkg_install` (checks before installing)

### Dry-run Support

Both installers respect `DRY_RUN` environment variable:
```bash
if [[ "$dry_run" == true ]]; then
  log_info "Would install and configure ufw (dry-run)"
  return 0
fi
```

## Testing Strategy

### Unit Testing
- Shellcheck all new scripts
- Syntax validation via `./test.sh`
- Dry-run mode verification

### Integration Testing
Test on all supported distros:
- Ubuntu 24.04 (Docker + VM)
- Debian 12 (Docker + VM)
- Arch (Docker + VM)

Verify:
1. Server role installs without errors
2. fail2ban service is active
3. ufw is enabled with correct rules (`sudo ufw status verbose`)
4. No zsh/oh-my-zsh installed
5. neovim available (not vim)
6. Docker CLI functional

### Homelab Role Testing
1. Homelab role includes all server packages
2. Additional packages installed (net-tools, iproute2, sops)
3. No duplicate installations

## Migration Path

Existing server role users:
1. Pull updated code
2. Re-run `./install.sh --role server`
3. Installer will skip already-installed packages
4. New security tools will be added
5. zsh/oh-my-zsh remain if previously installed (not removed)

Clean installations:
- Server role installs lean, secure baseline
- Homelab role adds networking/secrets tools

## Future Enhancements

Potential additions (not in this iteration):
- Docker helper tools in homelab (ctop, lazydocker, dive)
- Monitoring exporters (node_exporter for Prometheus)
- Backup tools (restic, borgbackup)
- Network debugging (tcpdump, mtr, iperf3)

These can be added as separate package groups or via `--packages` flag.
