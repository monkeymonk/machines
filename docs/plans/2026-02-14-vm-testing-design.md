# VM Testing Infrastructure Design

**Date:** 2026-02-14
**Status:** Approved Design
**Target:** Local development testing for Debian, Ubuntu, and Arch

## Overview

This design describes a hybrid testing infrastructure for the `machines` bootstrap toolkit using Docker for quick validation and Vagrant VMs for full integration testing. The infrastructure supports testing across Ubuntu 24.04, Debian 12 server, and Arch Linux with ephemeral environments and automated test execution.

## Goals

- Enable quick validation tests during development (2-5 minutes)
- Support full integration testing before releases (10-20 minutes per distro)
- Test across Ubuntu 24.04, Debian 12 server, and Arch Linux
- Provide simple Makefile interface for test execution
- Use ephemeral environments (no state pollution)
- Support per-distro targeting for focused testing
- Enable debugging with interactive VM sessions

## Non-Goals

- CI/CD integration (local development only)
- Testing older distro versions (Ubuntu 22.04, Debian 11, etc.)
- Debian desktop testing (server only)
- Cross-platform host support (Linux host assumed)
- Performance benchmarking
- Automated regression testing

## Architecture Overview

### Directory Structure

```
machines/
├── Makefile                    # Main test interface (NEW)
├── test/                       # Test infrastructure (NEW)
│   ├── docker/
│   │   ├── run-docker-test.sh       # Docker test executor
│   │   ├── Dockerfile.ubuntu24      # Ubuntu 24.04 image
│   │   ├── Dockerfile.debian12      # Debian 12 server image
│   │   └── Dockerfile.arch          # Arch latest image
│   ├── vagrant/
│   │   ├── Vagrantfile              # Multi-machine VM config
│   │   ├── provision.sh             # VM provisioning script
│   │   └── run-vagrant-test.sh      # VM test executor
│   └── lib/
│       ├── test-common.sh           # Shared test functions
│       └── test-matrix.sh           # Distro/test matrix definitions
├── install.sh                  # Main installer (existing)
├── test.sh                     # Shellcheck/syntax tests (existing)
└── ... (existing structure)
```

### Technology Stack

- **Make:** Test orchestration and interface
- **Docker:** Quick validation tests (systemd-enabled base images)
- **Vagrant:** Full integration VMs (libvirt or VirtualBox provider)
- **Bash:** All test execution scripts

### Test Types

**1. Quick validation (Docker):**
- Syntax checks (existing test.sh)
- Package availability verification
- Core package installs (no services)
- Role dry-run execution
- Execution time: ~2-5 minutes total

**2. Full integration (Vagrant):**
- Complete role installations
- Service starts and health checks
- Desktop environment testing (Hyprland, GDM)
- Idempotency verification (run installer twice)
- Execution time: ~10-20 minutes per distro

### Distro Matrix

| Distro | Quick (Docker) | Full (Vagrant) | Notes |
|--------|---------------|----------------|-------|
| Ubuntu 24.04 | ✅ | ✅ | Desktop + server testing |
| Debian 12 | ✅ | ✅ | Server only, no GUI |
| Arch latest | ✅ | ✅ | Rolling release, latest packages |

## Docker Quick Test System

### Docker Images Approach

Base images with systemd enabled for basic service testing:
- Ubuntu 24.04: `ubuntu:24.04` + systemd setup
- Debian 12: `debian:12` + systemd setup
- Arch: `archlinux:latest` + systemd setup

### Dockerfile Pattern

Example for Ubuntu 24.04 (`test/docker/Dockerfile.ubuntu24`):

```dockerfile
FROM ubuntu:24.04

# Enable systemd
RUN apt-get update && \
    apt-get install -y systemd systemd-sysv && \
    apt-get clean

# Install basic dependencies for testing
RUN apt-get install -y \
    sudo curl git wget \
    ca-certificates

# Create test user (non-root execution)
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /machines
```

### Test Execution

Script: `test/docker/run-docker-test.sh`

**Execution flow:**
1. Build distro-specific Docker image
2. Mount `machines` repo into container at `/machines`
3. Run test sequence as testuser:
   - `./test.sh` (shellcheck + syntax)
   - `./install.sh --role server --dry-run` (validate roles work)
   - `./install.sh --packages core` (quick install test)
   - Verify key packages installed: `command -v git zsh bat`
4. Exit and destroy container
5. Report pass/fail with exit code

### Quick Test Scope

- ✅ Scripts run without syntax errors
- ✅ Package managers work (apt/pacman)
- ✅ Core packages install successfully
- ✅ Role configuration is valid
- ❌ No service startup testing
- ❌ No desktop environment testing
- ❌ No full dependency resolution

### Execution Time

~2-3 minutes per distro (parallel execution possible)

## Vagrant Full Integration System

### Vagrantfile Structure

Multi-machine configuration (`test/vagrant/Vagrantfile`):

```ruby
Vagrant.configure("2") do |config|
  # Ubuntu 24.04 VM
  config.vm.define "ubuntu24" do |ubuntu|
    ubuntu.vm.box = "bento/ubuntu-24.04"
    ubuntu.vm.provider "libvirt" do |v|
      v.memory = 4096
      v.cpus = 2
      v.graphics_type = "spice"  # For desktop testing
    end
    ubuntu.vm.provision "shell", path: "provision.sh",
      env: {"TEST_DISTRO" => "ubuntu24", "TEST_ROLE" => "workstation"}
  end

  # Debian 12 Server VM
  config.vm.define "debian12" do |debian|
    debian.vm.box = "debian/bookworm64"
    debian.vm.provider "libvirt" do |v|
      v.memory = 2048
      v.cpus = 2
      v.graphics_type = "none"  # Server only, no GUI
    end
    debian.vm.provision "shell", path: "provision.sh",
      env: {"TEST_DISTRO" => "debian12", "TEST_ROLE" => "server"}
  end

  # Arch VM
  config.vm.define "arch" do |arch|
    arch.vm.box = "archlinux/archlinux"
    arch.vm.provider "libvirt" do |v|
      v.memory = 4096
      v.cpus = 2
      v.graphics_type = "spice"
    end
    arch.vm.provision "shell", path: "provision.sh",
      env: {"TEST_DISTRO" => "arch", "TEST_ROLE" => "workstation"}
  end
end
```

### Provisioning Script

Script: `test/vagrant/provision.sh`

**Execution flow:**
1. Copy machines repo into VM: `/home/vagrant/machines`
2. Run full installation based on TEST_ROLE
3. Verify installation:
   - Check installed packages exist
   - Test service health (for services role)
   - Verify GDM session file (for desktop roles)
   - Check systemd units are enabled
4. Run idempotency test (install again, should skip)
5. Collect logs to `/vagrant/test-results/`
6. Exit with status code

### Full Test Scope

- ✅ Complete package installations
- ✅ Service startup and health checks
- ✅ Systemd unit configuration
- ✅ Desktop environment integration (GDM, Hyprland)
- ✅ Idempotency verification
- ✅ Role-specific validation

### Provider Choice

- **Primary:** libvirt (KVM, native Linux performance)
- **Fallback:** VirtualBox (cross-platform, easier setup)
- Makefile detects available provider automatically

### Execution Time

~10-15 minutes per distro (can run parallel with sufficient RAM)

### Resource Requirements

- **Minimum:** 8GB RAM host (run VMs sequentially)
- **Recommended:** 16GB RAM host (run 2 VMs parallel)

## Makefile Interface

### Main Targets

```makefile
# Quick tests (Docker) - fast validation
test-quick:           # All distros, Docker quick tests
test-quick-ubuntu24:  # Ubuntu 24.04 only
test-quick-debian12:  # Debian 12 only
test-quick-arch:      # Arch only

# Full tests (Vagrant) - complete integration
test-full:            # All distros, Vagrant VMs
test-full-ubuntu24:   # Ubuntu 24.04 VM only
test-full-debian12:   # Debian 12 server VM only
test-full-arch:       # Arch VM only

# Combined workflows
test-all:             # Quick + Full for all distros
test-ubuntu24:        # Quick + Full for Ubuntu 24.04
test-debian12:        # Quick + Full for Debian 12
test-arch:            # Quick + Full for Arch

# Infrastructure management
test-clean:           # Remove Docker images and Vagrant VMs
test-shell-ubuntu24:  # SSH into Ubuntu VM for debugging
test-shell-debian12:  # SSH into Debian VM for debugging
test-shell-arch:      # SSH into Arch VM for debugging

# Legacy
test:                 # Existing test.sh (shellcheck/syntax)
```

### Usage Examples

```bash
# Daily development - quick validation
make test-quick

# Before release - full integration
make test-full

# Debug specific distro
make test-shell-ubuntu24  # Opens SSH session in VM

# Test single distro completely
make test-ubuntu24  # Quick + Full

# Test only Debian
make test-quick-debian12  # Fast check
make test-full-debian12   # Full validation

# Clean up everything
make test-clean
```

### Makefile Features

- Parallel execution where possible (Docker tests)
- Color-coded output (green=pass, red=fail)
- Progress indicators for long-running VM tests
- Automatic provider detection (libvirt vs VirtualBox)
- Prerequisite checking (Docker/Vagrant installed)

### Example Output

```
$ make test-quick
[1/3] Testing Ubuntu 24.04 (Docker)... ✓ PASS (2m 15s)
[2/3] Testing Debian 12 (Docker)...    ✓ PASS (1m 58s)
[3/3] Testing Arch (Docker)...         ✓ PASS (2m 32s)

Quick tests: 3/3 passed
```

## Test Execution Flow

### Quick Test Flow (Docker)

```
make test-quick-ubuntu24
  ↓
1. Check Docker installed
  ↓
2. Build Docker image (cached if exists)
   - FROM ubuntu:24.04
   - Install systemd + sudo
   - Create testuser
  ↓
3. Run container with machines repo mounted
  ↓
4. Execute test sequence inside container:
   a. ./test.sh                           # shellcheck + syntax
   b. ./install.sh --role server --dry-run # validate role
   c. ./install.sh --packages core         # install core packages
   d. Verify installations:
      - command -v git zsh bat cargo
      - check rustup installed
  ↓
5. Capture exit code and logs
  ↓
6. Destroy container
  ↓
7. Report: PASS/FAIL + execution time
```

### Full Test Flow (Vagrant)

```
make test-full-ubuntu24
  ↓
1. Check Vagrant + provider installed
  ↓
2. Vagrant up ubuntu24
   - Download base box (cached)
   - Create VM (4GB RAM, 2 CPU)
   - Boot with graphics support
  ↓
3. Provision VM (provision.sh):
   a. Copy machines repo to /home/vagrant/machines
   b. Run: ./install.sh --role workstation
   c. Verify installations:
      - Packages installed
      - Services enabled (check systemctl)
      - GDM session file exists (if desktop role)
   d. Test idempotency:
      - Run ./install.sh --role workstation again
      - Should complete without errors, skip installed
  ↓
4. Collect results to test-results/ubuntu24/
   - Installation logs
   - Package list (dpkg -l / pacman -Q)
   - Service status (systemctl list-units)
  ↓
5. Vagrant destroy ubuntu24 (ephemeral)
  ↓
6. Report: PASS/FAIL + execution time + logs location
```

### Parallel Execution Strategy

- **Docker tests:** Run all 3 distros in parallel (independent)
- **Vagrant tests:** Sequential by default (RAM constraints)
- **Parallel VMs:** `PARALLEL=yes make test-full` (requires 16GB+ RAM)

### Test Results Structure

```
test-results/
├── quick/
│   ├── ubuntu24.log
│   ├── debian12.log
│   └── arch.log
└── full/
    ├── ubuntu24/
    │   ├── provision.log
    │   ├── install.log
    │   └── packages.txt
    ├── debian12/
    └── arch/
```

## Error Handling & Reporting

### Failure Detection

**Docker tests fail when:**
- Image build fails (missing base image, network issues)
- Shellcheck finds errors (`test.sh` fails)
- Dry-run execution errors (invalid role syntax)
- Package installation fails (package not found, network timeout)
- Verification commands fail (installed package not in PATH)

**Vagrant tests fail when:**
- VM provisioning fails (base box download, boot issues)
- Installation script exits non-zero
- Service health checks fail (systemd unit not active)
- Required files missing (GDM session file for desktop roles)
- Idempotency test fails (second run produces errors)

### Exit Codes

```bash
0   = All tests passed
1   = Test execution failed
2   = Prerequisites missing (Docker/Vagrant not installed)
3   = Infrastructure error (can't build image, can't start VM)
```

### Log Collection

- All output saved to `test-results/{quick,full}/{distro}/`
- STDOUT + STDERR captured separately
- Timestamped log files
- **Failed tests:** Logs printed to terminal + saved to file
- **Passed tests:** Summary only, logs available in test-results/

### Terminal Output Format

**Success:**
```bash
$ make test-full-ubuntu24

[Ubuntu 24.04 Full Test]
  ✓ Vagrant up                    (45s)
  ✓ Provision VM                  (12s)
  ✓ Install workstation role      (8m 23s)
  ✓ Verify packages installed     (3s)
  ✓ Check GDM session file        (1s)
  ✓ Idempotency test             (2m 15s)
  ✓ Collect logs                  (2s)
  ✓ Destroy VM                    (8s)

PASS: Ubuntu 24.04 full test (11m 57s)
Logs: test-results/full/ubuntu24/
```

**Failure:**
```bash
$ make test-full-debian12

[Debian 12 Full Test]
  ✓ Vagrant up                    (38s)
  ✓ Provision VM                  (10s)
  ✗ Install server role           (FAILED)

ERROR: Installation failed
Exit code: 1

Last 20 lines of log:
[ERROR] Package 'build-essential' not found
[ERROR] Failed to install core packages
...

Full logs: test-results/full/debian12/install.log

To debug interactively:
  make test-shell-debian12
```

### Debugging Helpers

```bash
make test-shell-<distro>         # SSH into VM (kept alive for debugging)
VERBOSE=1 make test-quick        # Show all command output
KEEP_VM=1 make test-full-ubuntu24 # Don't destroy VM on failure
```

## Implementation Checklist

### Infrastructure Setup

- [ ] Create `test/` directory structure
- [ ] Create `test/docker/` for Docker tests
- [ ] Create `test/vagrant/` for Vagrant VMs
- [ ] Create `test/lib/` for shared test functions

### Docker Quick Tests

- [ ] Create `test/docker/Dockerfile.ubuntu24`
- [ ] Create `test/docker/Dockerfile.debian12`
- [ ] Create `test/docker/Dockerfile.arch`
- [ ] Create `test/docker/run-docker-test.sh`
- [ ] Implement test sequence (shellcheck, dry-run, core install)
- [ ] Add package verification checks

### Vagrant Full Tests

- [ ] Create `test/vagrant/Vagrantfile` with 3 VM definitions
- [ ] Create `test/vagrant/provision.sh`
- [ ] Implement installation verification
- [ ] Implement service health checks
- [ ] Implement idempotency testing
- [ ] Add log collection to test-results/

### Makefile

- [ ] Create root `Makefile` with all targets
- [ ] Implement `test-quick` targets (per-distro + all)
- [ ] Implement `test-full` targets (per-distro + all)
- [ ] Implement `test-<distro>` combined targets
- [ ] Implement `test-shell-<distro>` debugging targets
- [ ] Implement `test-clean` cleanup target
- [ ] Add prerequisite checks (Docker/Vagrant installed)
- [ ] Add provider auto-detection (libvirt/VirtualBox)
- [ ] Add color-coded output
- [ ] Add progress indicators

### Testing & Validation

- [ ] Test Docker quick tests on all 3 distros
- [ ] Test Vagrant full tests on all 3 distros
- [ ] Verify ephemeral behavior (clean destroy)
- [ ] Test per-distro targeting
- [ ] Test debugging with test-shell-*
- [ ] Verify log collection
- [ ] Test error reporting
- [ ] Test idempotency verification
- [ ] Validate with libvirt provider
- [ ] Validate with VirtualBox provider (fallback)

### Documentation

- [ ] Update main README.md with testing instructions
- [ ] Add TESTING.md with detailed usage examples
- [ ] Document prerequisite installation (Docker, Vagrant, libvirt)
- [ ] Add troubleshooting section
- [ ] Document resource requirements

## Prerequisites

### Required Tools

**For quick tests:**
- Docker (version 20.10+)

**For full tests:**
- Vagrant (version 2.3+)
- libvirt + QEMU (recommended) OR VirtualBox 7.0+
- Vagrant libvirt plugin: `vagrant plugin install vagrant-libvirt`

### Installation

**Ubuntu/Debian:**
```bash
# Docker
sudo apt install docker.io
sudo usermod -aG docker $USER

# Vagrant + libvirt
sudo apt install vagrant qemu-kvm libvirt-daemon-system
vagrant plugin install vagrant-libvirt
sudo usermod -aG libvirt $USER
```

**Arch:**
```bash
# Docker
sudo pacman -S docker
sudo usermod -aG docker $USER
sudo systemctl enable --now docker

# Vagrant + libvirt
sudo pacman -S vagrant qemu libvirt
vagrant plugin install vagrant-libvirt
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd
```

## Limitations & Considerations

### Known Limitations

1. **Docker systemd limitations:**
   - Limited systemd support in containers
   - Can't test full service startup/management
   - No desktop environment testing in Docker

2. **Resource requirements:**
   - Full VM tests require significant RAM (4GB per VM)
   - Parallel VM execution needs 16GB+ host RAM
   - Disk space for Vagrant boxes (~2GB per distro)

3. **Network dependencies:**
   - Tests require internet for package downloads
   - Vagrant box downloads on first run
   - Network failures will cause test failures

4. **Host platform:**
   - Designed for Linux hosts only
   - libvirt provider Linux-specific
   - VirtualBox fallback for other platforms (not tested)

5. **Test coverage:**
   - No testing of actual desktop usage (just installation)
   - No performance testing
   - No upgrade/migration testing

## Future Enhancements

### Potential Additions

1. **CI/CD integration:**
   - GitHub Actions workflow
   - Automated testing on PRs
   - Test result badges

2. **Additional distros:**
   - Ubuntu 22.04 LTS
   - Fedora/RHEL testing
   - Alpine Linux (containers only)

3. **Test improvements:**
   - Smoke tests for installed packages
   - Network connectivity tests
   - Disk space usage validation

4. **Performance:**
   - Cached package downloads
   - Incremental Docker layers
   - Snapshot-based VM reuse (optional)

5. **Reporting:**
   - HTML test reports
   - Test duration tracking
   - Historical comparison

---

**End of Design Document**
