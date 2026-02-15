# Testing Infrastructure

## Overview

Hybrid Docker/Vagrant testing infrastructure for validating bootstrap scripts across multiple Linux distributions.

- **Quick tests (Docker):** Fast validation in containers (~2-5 minutes)
- **Full tests (Vagrant):** Complete integration in VMs (~10-20 minutes per distro)

## Prerequisites

### Docker (for quick tests)

**Ubuntu/Debian:**
```bash
sudo apt install docker.io
sudo usermod -aG docker $USER
newgrp docker
```

**Arch:**
```bash
sudo pacman -S docker
sudo usermod -aG docker $USER
sudo systemctl enable --now docker
newgrp docker
```

### Vagrant + libvirt (for full tests)

**Ubuntu/Debian:**
```bash
sudo apt install vagrant qemu-kvm libvirt-daemon-system libvirt-clients
vagrant plugin install vagrant-libvirt
sudo usermod -aG libvirt $USER
newgrp libvirt
```

**Arch:**
```bash
sudo pacman -S vagrant qemu libvirt
vagrant plugin install vagrant-libvirt
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd
newgrp libvirt
```

## Quick Start

```bash
# Quick validation (Docker) - all distros
make test-quick

# Full integration (Vagrant) - all distros
make test-full

# Complete test suite (Quick + Full)
make test-all

# Clean up everything
make test-clean
```

## Test Types

### Quick Tests (Docker)
- **Duration:** 2-5 minutes per distro
- **What's tested:**
  - Shellcheck and syntax validation
  - Dry-run execution
  - Core package installation
  - Basic package verification
- **When to use:** During development, before commits

### Full Tests (Vagrant)
- **Duration:** 10-20 minutes per distro
- **What's tested:**
  - Complete role installation
  - Service startup and health
  - Desktop environment integration (GDM, Hyprland)
  - Idempotency (second run skips installed packages)
  - Results collection and logging
- **When to use:** Before releases, major changes

## Distro Matrix

| Distribution | Quick (Docker) | Full (Vagrant) | Role | Notes |
|--------------|----------------|----------------|------|-------|
| Ubuntu 24.04 | ✅ | ✅ | workstation | Desktop testing with GUI |
| Debian 12 | ✅ | ✅ | server | Server only, no graphics |
| Arch (latest) | ✅ | ✅ | workstation | Rolling release |

## Usage Examples

### Test Single Distro

```bash
# Quick test only
make test-quick-ubuntu24
make test-quick-debian12
make test-quick-arch

# Full test only
make test-full-ubuntu24
make test-full-debian12
make test-full-arch

# Both quick + full
make test-ubuntu24
make test-debian12
make test-arch
```

### Debug Failed Tests

```bash
# Start VM and SSH into it for debugging
make test-shell-ubuntu24
make test-shell-debian12
make test-shell-arch

# Inside the VM:
cd /home/vagrant/machines
./install.sh --role workstation
# Debug interactively...
exit

# Destroy VM when done
cd test/vagrant
vagrant destroy -f ubuntu24
```

### View Test Results

```bash
# Quick test logs
ls -la test-results/quick/

# Full test logs
ls -la test-results/full/ubuntu24/
cat test-results/full/ubuntu24/install.log
cat test-results/full/ubuntu24/packages.txt
```

## Debugging

### Check Prerequisites

```bash
# Verify Docker is working
docker ps
docker run hello-world

# Verify Vagrant is working
vagrant --version
vagrant plugin list
```

### Docker Test Issues

```bash
# Check if images built
docker images | grep machines-test

# Manually test Docker script
cd test/docker
./run-docker-test.sh ubuntu24

# Check container logs
docker ps -a
docker logs <container-id>
```

### Vagrant Test Issues

```bash
# Check Vagrant status
cd test/vagrant
vagrant status

# View provision logs
vagrant up ubuntu24
# Logs appear in terminal during provision

# SSH into VM
vagrant ssh ubuntu24

# Check provision script logs
cat /tmp/install.log
cat /tmp/install-second.log

# Destroy and retry
vagrant destroy -f ubuntu24
vagrant up ubuntu24
```

## Troubleshooting

### Docker: Permission Denied

**Problem:** `docker: permission denied while trying to connect to the Docker daemon`

**Solution:**
```bash
sudo usermod -aG docker $USER
newgrp docker
# Or logout/login
```

### Vagrant: No Provider Available

**Problem:** `No usable default provider could be found`

**Solution:**
```bash
# Install vagrant-libvirt plugin
vagrant plugin install vagrant-libvirt

# Verify libvirt is running
sudo systemctl status libvirtd
sudo systemctl enable --now libvirtd
```

### Vagrant: Box Download Fails

**Problem:** `An error occurred while downloading the remote file`

**Solution:**
```bash
# Manually download box
vagrant box add bento/ubuntu-24.04
vagrant box add debian/bookworm64
vagrant box add archlinux/archlinux

# Verify boxes
vagrant box list
```

### VM Won't Boot

**Problem:** Vagrant VM fails to start

**Solution:**
```bash
# Check virtualization enabled
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should be > 0

# Check libvirt permissions
sudo usermod -aG libvirt $USER
newgrp libvirt

# Try VirtualBox instead
vagrant plugin install vagrant-vbguest
# Edit Vagrantfile to use :virtualbox provider
```

### Tests Failing Due to Network

**Problem:** Package installation fails due to network

**Solution:**
```bash
# Check host network
ping -c 3 8.8.8.8

# Inside VM
vagrant ssh ubuntu24
ping -c 3 archive.ubuntu.com
curl -I https://github.com

# Restart libvirt networking
sudo systemctl restart libvirtd
```

### Out of Disk Space

**Problem:** `No space left on device`

**Solution:**
```bash
# Clean Docker
docker system prune -a

# Clean Vagrant boxes
vagrant box prune

# Remove test results
make test-clean

# Check disk usage
df -h
du -sh ~/.vagrant.d/boxes/
```

## Performance Tips

### Speed Up Docker Tests

```bash
# Pre-build images
cd test/docker
docker build -f Dockerfile.ubuntu24 -t machines-test:ubuntu24 .
docker build -f Dockerfile.debian12 -t machines-test:debian12 .
docker build -f Dockerfile.arch -t machines-test:arch .

# Then run tests (will use cached images)
make test-quick
```

### Parallelize Tests

Docker tests can run in parallel:
```bash
# In separate terminals
make test-quick-ubuntu24 &
make test-quick-debian12 &
make test-quick-arch &
wait
```

Vagrant tests run sequentially (RAM constraints).

### Keep VMs for Debugging

Don't auto-destroy VMs on failure:
```bash
# Manually run Vagrant
cd test/vagrant
vagrant up ubuntu24
# If it fails, VM stays up for debugging
```

## Test Coverage

### What's Tested

- ✅ Script syntax (shellcheck)
- ✅ Package manager functionality
- ✅ Core package installation
- ✅ Role-based installation
- ✅ Idempotency (re-run safety)
- ✅ Service enablement (Vagrant only)
- ✅ Desktop integration (Vagrant workstation role)

### What's NOT Tested

- ❌ Actual desktop usage
- ❌ Performance benchmarks
- ❌ Upgrade/migration scenarios
- ❌ Multi-user setups
- ❌ Security hardening

## CI/CD Integration (Future)

This infrastructure is designed for local testing. For CI/CD:

```yaml
# Example GitHub Actions (future)
name: Test
on: [push, pull_request]
jobs:
  quick-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: make test-quick
```

## Additional Resources

- Main README: [README.md](README.md)
- Design Document: [docs/plans/2026-02-14-vm-testing-design.md](docs/plans/2026-02-14-vm-testing-design.md)
- Implementation Plan: [docs/plans/2026-02-14-vm-testing-plan.md](docs/plans/2026-02-14-vm-testing-plan.md)
