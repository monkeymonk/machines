# VM Testing Infrastructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build hybrid Docker/Vagrant testing infrastructure for validating bootstrap scripts across Ubuntu 24.04, Debian 12, and Arch Linux.

**Architecture:** Docker containers for quick validation (2-5 min), Vagrant VMs for full integration testing (10-20 min). Makefile orchestrates everything with per-distro targeting. Ephemeral environments guarantee clean testing.

**Tech Stack:** Docker, Vagrant, libvirt/VirtualBox, Make, Bash

**Implementation Strategy:** Ollama-first workflow - use local-code skill for generation, local-review for validation, Claude for integration checkpoints.

---

## Phase 1: Docker Quick Test Infrastructure

### Task 1: Create Ubuntu 24.04 Dockerfile base layer

**Tool:** local-code

**Files:**
- Create: `test/docker/Dockerfile.ubuntu24`

**Prompt for local-code:**
```
Create a Dockerfile for Ubuntu 24.04 testing with:
- FROM ubuntu:24.04
- Install systemd and systemd-sysv
- Install basic tools: sudo, curl, git, wget, ca-certificates
- Clean up apt cache with apt-get clean
- Use minimal layers, combine RUN commands
```

**Expected output:** ~10 line Dockerfile with base system setup

**Validation:** Check file exists and has proper FROM statement

---

### Task 2: Add testuser to Ubuntu Dockerfile

**Tool:** local-code

**Files:**
- Modify: `test/docker/Dockerfile.ubuntu24`

**Prompt for local-code:**
```
Add to existing Dockerfile.ubuntu24:
- Create user 'testuser' with home directory and bash shell
- Add testuser to sudoers with NOPASSWD for all commands
- Set WORKDIR to /machines
- Keep it simple, 3-4 lines
```

**Expected output:** User creation and sudo setup appended

**Validation:** `grep testuser test/docker/Dockerfile.ubuntu24`

---

### Task 3: Create Debian 12 Dockerfile base layer

**Tool:** local-code

**Files:**
- Create: `test/docker/Dockerfile.debian12`

**Prompt for local-code:**
```
Create a Dockerfile for Debian 12 server testing:
- FROM debian:12
- Install systemd and systemd-sysv
- Install basic tools: sudo, curl, git, wget, ca-certificates
- Clean up apt cache with apt-get clean
- Use minimal layers, combine RUN commands
```

**Expected output:** ~10 line Dockerfile similar to Ubuntu version

**Validation:** Check file exists and has proper FROM statement

---

### Task 4: Add testuser to Debian Dockerfile

**Tool:** local-code

**Files:**
- Modify: `test/docker/Dockerfile.debian12`

**Prompt for local-code:**
```
Add to existing Dockerfile.debian12:
- Create user 'testuser' with home directory and bash shell
- Add testuser to sudoers with NOPASSWD for all commands
- Set WORKDIR to /machines
- Same pattern as Ubuntu version
```

**Expected output:** User creation and sudo setup appended

**Validation:** `grep testuser test/docker/Dockerfile.debian12`

---

### Task 5: Create Arch Linux Dockerfile base layer

**Tool:** local-code

**Files:**
- Create: `test/docker/Dockerfile.arch`

**Prompt for local-code:**
```
Create a Dockerfile for Arch Linux testing:
- FROM archlinux:latest
- Run pacman -Syu --noconfirm to update system
- Install systemd, sudo, git, curl, wget
- Clean pacman cache with pacman -Scc --noconfirm
- Use minimal layers, combine RUN commands
```

**Expected output:** ~10 line Dockerfile with Arch-specific commands

**Validation:** Check file exists and uses pacman commands

---

### Task 6: Add testuser to Arch Dockerfile

**Tool:** local-code

**Files:**
- Modify: `test/docker/Dockerfile.arch`

**Prompt for local-code:**
```
Add to existing Dockerfile.arch:
- Create user 'testuser' with home directory and bash shell
- Add testuser to sudoers with NOPASSWD for all commands
- Set WORKDIR to /machines
- Same pattern as Ubuntu/Debian versions
```

**Expected output:** User creation and sudo setup appended

**Validation:** `grep testuser test/docker/Dockerfile.arch`

---

### CHECKPOINT 1: Review Dockerfiles with Ollama

**Tool:** local-review

**Files:**
- Review: `test/docker/Dockerfile.ubuntu24`
- Review: `test/docker/Dockerfile.debian12`
- Review: `test/docker/Dockerfile.arch`

**Prompt for local-review:**
```
Review these three Dockerfiles for:
- Security issues (exposed secrets, unnecessary privileges)
- Missing apt-get/pacman cache cleanup
- Incorrect systemd setup
- Sudo misconfiguration (should be NOPASSWD)
- Unnecessary layers or bloat
- Consistency across all three files
```

**Expected findings:** Should flag any issues, confirm consistency

**Action:** Fix any issues found before proceeding

---

### Task 7: Create directory structure

**Tool:** bash (direct execution)

**Commands:**
```bash
mkdir -p test/docker
mkdir -p test/vagrant
mkdir -p test/lib
mkdir -p test-results/quick
mkdir -p test-results/full
```

**Validation:** `ls -la test/`

**Commit:**
```bash
git add test/docker/Dockerfile.*
git commit -m "feat: add Docker test images for Ubuntu, Debian, Arch

- Ubuntu 24.04 with systemd
- Debian 12 server with systemd
- Arch latest with systemd
- All include testuser with passwordless sudo"
```

---

## Phase 2: Docker Test Executor

### Task 8: Create test-common.sh helper functions (part 1)

**Tool:** local-code

**Files:**
- Create: `test/lib/test-common.sh`

**Prompt for local-code:**
```
Create test/lib/test-common.sh with bash helper functions:

1. Shebang and strict mode:
   #!/usr/bin/env bash
   set -euo pipefail

2. Function: log_test_info() - echoes with [TEST] prefix and timestamp
3. Function: log_test_error() - echoes to stderr with [ERROR] prefix
4. Function: log_test_pass() - green colored PASS message
5. Function: log_test_fail() - red colored FAIL message

Follow the pattern from existing lib/log.sh but prefix with "test"
Keep it under 30 lines total
```

**Expected output:** Basic logging helpers for test scripts

**Validation:** `source test/lib/test-common.sh && log_test_info "test"`

---

### Task 9: Create test-common.sh helper functions (part 2)

**Tool:** local-code

**Files:**
- Modify: `test/lib/test-common.sh`

**Prompt for local-code:**
```
Add to existing test/lib/test-common.sh:

1. Function: check_command_exists(cmd) - returns 0 if command exists, 1 otherwise
2. Function: measure_time() - returns timestamp for timing measurements
3. Function: format_duration(start_time, end_time) - returns human-readable duration

Use command -v for command checking
Use date +%s for timestamps
Keep functions simple, ~5 lines each
```

**Expected output:** Utility functions appended

**Validation:** Source file and test each function

---

### Task 10: Create Docker test executor script skeleton

**Tool:** local-code

**Files:**
- Create: `test/docker/run-docker-test.sh`

**Prompt for local-code:**
```
Create test/docker/run-docker-test.sh with:

1. Shebang and strict mode
2. Source ../lib/test-common.sh
3. Usage function: show how to run script with distro argument
4. Main function structure (empty for now):
   - check_prerequisites()
   - build_image()
   - run_tests()
   - cleanup()
   - main()
5. Accept distro name as $1 (ubuntu24, debian12, arch)
6. Exit with usage if no arg provided

Just the skeleton, ~30 lines, no implementation yet
```

**Expected output:** Script structure with function placeholders

**Validation:** `bash -n test/docker/run-docker-test.sh`

---

### Task 11: Implement check_prerequisites() function

**Tool:** local-code

**Files:**
- Modify: `test/docker/run-docker-test.sh`

**Prompt for local-code:**
```
Implement check_prerequisites() function in run-docker-test.sh:

- Check if docker command exists using check_command_exists
- If missing: log_test_error "Docker not installed" and exit 2
- Check if Dockerfile exists for the given distro
- If missing: log_test_error "Dockerfile.$DISTRO not found" and exit 2
- Log success if all checks pass
- Keep it under 15 lines
```

**Expected output:** Prerequisites validation function

**Validation:** Run script without Docker installed (should fail gracefully)

---

### Task 12: Implement build_image() function

**Tool:** local-code

**Files:**
- Modify: `test/docker/run-docker-test.sh`

**Prompt for local-code:**
```
Implement build_image() function in run-docker-test.sh:

- Takes distro name as argument
- Build Docker image: docker build -f Dockerfile.$DISTRO -t machines-test:$DISTRO .
- Log progress: "Building Docker image for $DISTRO..."
- Capture exit code
- If build fails: log_test_error and return 1
- If success: log_test_info "Image built successfully"
- Return 0 on success
```

**Expected output:** Docker build wrapper function

**Validation:** Run function (should build image)

---

### Task 13: Implement run_tests() function (part 1)

**Tool:** local-code

**Files:**
- Modify: `test/docker/run-docker-test.sh`

**Prompt for local-code:**
```
Implement run_tests() function in run-docker-test.sh:

- Takes distro name as argument
- Run Docker container:
  docker run --rm -v "$(pwd)/../..:/machines" machines-test:$DISTRO bash -c "..."
- Inside container, run as testuser:
  su - testuser -c "cd /machines && ./test.sh"
- Capture exit code
- If test.sh fails: log_test_fail and return 1
- If success: log_test_pass "Shellcheck passed"
- Return 0 on success

Just this first test for now, ~20 lines
```

**Expected output:** Container execution with test.sh

**Validation:** Run and check exit code

---

### Task 14: Implement run_tests() function (part 2)

**Tool:** local-code

**Files:**
- Modify: `test/docker/run-docker-test.sh`

**Prompt for local-code:**
```
Extend run_tests() function in run-docker-test.sh:

After the test.sh check, add:
- Run dry-run test: ./install.sh --role server --dry-run
- Capture exit code
- If fails: log_test_fail "Dry-run failed" and return 1
- If success: log_test_pass "Dry-run passed"

Keep container command structure same, just add this test
~10 additional lines
```

**Expected output:** Dry-run test added to sequence

**Validation:** Run and verify both tests execute

---

### Task 15: Implement run_tests() function (part 3)

**Tool:** local-code

**Files:**
- Modify: `test/docker/run-docker-test.sh`

**Prompt for local-code:**
```
Extend run_tests() function in run-docker-test.sh:

After dry-run test, add:
- Install core packages: ./install.sh --packages core
- Verify installations: command -v git zsh bat cargo
- If any command missing: log_test_fail and return 1
- If all present: log_test_pass "Core packages installed"

~15 additional lines
```

**Expected output:** Package installation test added

**Validation:** Run and verify package installation works

---

### Task 16: Implement cleanup() and main() functions

**Tool:** local-code

**Files:**
- Modify: `test/docker/run-docker-test.sh`

**Prompt for local-code:**
```
Implement cleanup() and main() in run-docker-test.sh:

cleanup():
- Remove Docker container (docker rm -f if exists)
- Log cleanup action
- ~5 lines

main():
- Parse $1 as distro name
- Call check_prerequisites
- Start timer with measure_time
- Call build_image
- Call run_tests
- Call cleanup
- Stop timer and log duration
- Exit with test result code
- ~15 lines

Make script executable at the end
```

**Expected output:** Complete working test script

**Validation:** `chmod +x test/docker/run-docker-test.sh && ./test/docker/run-docker-test.sh ubuntu24`

---

### CHECKPOINT 2: Review Docker test script

**Tool:** local-review

**Files:**
- Review: `test/docker/run-docker-test.sh`
- Review: `test/lib/test-common.sh`

**Prompt for local-review:**
```
Review Docker test infrastructure for:
- Error handling (set -euo pipefail, exit codes)
- Security issues (command injection, path traversal)
- Missing validation (args, file existence)
- Incorrect Docker usage (volume mounts, container cleanup)
- Race conditions or cleanup failures
- Logging completeness
```

**Expected findings:** Flag any issues with error handling or security

**Action:** Fix issues before proceeding

---

### Task 17: Test Docker quick tests manually

**Tool:** bash (manual execution)

**Commands:**
```bash
# Test each distro
cd test/docker
./run-docker-test.sh ubuntu24
./run-docker-test.sh debian12
./run-docker-test.sh arch

# Verify test-results created
ls -la ../../test-results/quick/
```

**Expected:** All three tests should pass, logs in test-results/

**Validation:** Exit code 0 for all three

**Commit:**
```bash
git add test/docker/run-docker-test.sh test/lib/test-common.sh
git commit -m "feat: add Docker quick test executor

- Runs shellcheck, dry-run, core package install
- Tests Ubuntu 24.04, Debian 12, Arch
- Collects logs to test-results/quick/
- ~2-3 min per distro"
```

---

## Phase 3: Makefile Quick Test Interface

### Task 18: Create Makefile with variables and helpers

**Tool:** local-code

**Files:**
- Create: `Makefile`

**Prompt for local-code:**
```
Create Makefile with:

1. .PHONY declarations for all test targets
2. Variables:
   - DOCKER := $(shell command -v docker)
   - TEST_DIR := test
   - RESULTS_DIR := test-results
3. Color codes for output:
   - GREEN, RED, YELLOW, NC (no color)
4. Helper function: check-docker target that verifies Docker installed
5. Default target: test (runs existing test.sh)

~25 lines, just foundation
```

**Expected output:** Makefile skeleton with variables

**Validation:** `make check-docker`

---

### Task 19: Add test-quick-ubuntu24 target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add to Makefile:

test-quick-ubuntu24 target:
- Depends on: check-docker
- Prints: "Testing Ubuntu 24.04 (Docker)..."
- Runs: $(TEST_DIR)/docker/run-docker-test.sh ubuntu24
- On success: prints green "✓ PASS"
- On failure: prints red "✗ FAIL" and exits 1
- Shows execution time

~10 lines, use color codes
```

**Expected output:** Single distro quick test target

**Validation:** `make test-quick-ubuntu24`

---

### Task 20: Add test-quick-debian12 target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-quick-debian12 target to Makefile:
- Same pattern as ubuntu24 target
- Changes: distro name, log message
- Keep DRY, ~8 lines
```

**Expected output:** Debian quick test target

**Validation:** `make test-quick-debian12`

---

### Task 21: Add test-quick-arch target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-quick-arch target to Makefile:
- Same pattern as ubuntu24/debian12
- Changes: distro name, log message
- Keep DRY, ~8 lines
```

**Expected output:** Arch quick test target

**Validation:** `make test-quick-arch`

---

### Task 22: Add test-quick aggregate target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-quick target to Makefile:
- Depends on: test-quick-ubuntu24 test-quick-debian12 test-quick-arch
- Prints header: "Running quick tests on all distros..."
- Prints summary: "Quick tests: X/3 passed"
- Uses color codes for summary

~8 lines
```

**Expected output:** Aggregate target for all quick tests

**Validation:** `make test-quick`

---

### Task 23: Test Makefile quick targets

**Tool:** bash (manual execution)

**Commands:**
```bash
# Test individual targets
make test-quick-ubuntu24
make test-quick-debian12
make test-quick-arch

# Test aggregate
make test-quick
```

**Expected:** All targets work, colored output, timing shown

**Validation:** Verify exit codes and output formatting

**Commit:**
```bash
git add Makefile
git commit -m "feat: add Makefile quick test targets

- test-quick-ubuntu24, test-quick-debian12, test-quick-arch
- test-quick runs all three distros
- Color-coded output with timing
- Docker prerequisite checking"
```

---

## Phase 4: Vagrant Full Integration Infrastructure

### Task 24: Create Vagrantfile header and config block

**Tool:** local-code

**Files:**
- Create: `test/vagrant/Vagrantfile`

**Prompt for local-code:**
```
Create test/vagrant/Vagrantfile with:

1. Ruby Vagrant.configure("2") block
2. Comment header explaining multi-machine setup
3. Global settings (none for now, just structure)

~10 lines, just the outer structure
```

**Expected output:** Vagrantfile skeleton

**Validation:** `cd test/vagrant && vagrant status`

---

### Task 25: Add Ubuntu 24.04 VM definition to Vagrantfile

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/Vagrantfile`

**Prompt for local-code:**
```
Add Ubuntu 24.04 VM definition to Vagrantfile:

config.vm.define "ubuntu24" do |ubuntu|
  - Box: bento/ubuntu-24.04
  - Provider: libvirt
  - Memory: 4096
  - CPUs: 2
  - Graphics: spice
  - Provision: shell script provision.sh
  - Environment variables: TEST_DISTRO=ubuntu24, TEST_ROLE=workstation
end

~15 lines inside the config block
```

**Expected output:** Ubuntu VM definition

**Validation:** `vagrant status ubuntu24`

---

### Task 26: Add Debian 12 VM definition to Vagrantfile

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/Vagrantfile`

**Prompt for local-code:**
```
Add Debian 12 VM definition to Vagrantfile:

config.vm.define "debian12" do |debian|
  - Box: debian/bookworm64
  - Provider: libvirt
  - Memory: 2048 (server only, less RAM)
  - CPUs: 2
  - Graphics: none (server, no GUI)
  - Provision: shell script provision.sh
  - Environment variables: TEST_DISTRO=debian12, TEST_ROLE=server
end

~15 lines, similar to Ubuntu but server-focused
```

**Expected output:** Debian VM definition

**Validation:** `vagrant status debian12`

---

### Task 27: Add Arch VM definition to Vagrantfile

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/Vagrantfile`

**Prompt for local-code:**
```
Add Arch VM definition to Vagrantfile:

config.vm.define "arch" do |arch|
  - Box: archlinux/archlinux
  - Provider: libvirt
  - Memory: 4096
  - CPUs: 2
  - Graphics: spice
  - Provision: shell script provision.sh
  - Environment variables: TEST_DISTRO=arch, TEST_ROLE=workstation
end

~15 lines, similar to Ubuntu pattern
```

**Expected output:** Arch VM definition

**Validation:** `vagrant status arch`

---

### CHECKPOINT 3: Review Vagrantfile

**Tool:** local-review

**Files:**
- Review: `test/vagrant/Vagrantfile`

**Prompt for local-review:**
```
Review Vagrantfile for:
- Syntax errors (Ruby)
- Incorrect box names or versions
- Resource allocation issues (RAM/CPU)
- Missing provider configuration
- Graphics settings (spice for desktop, none for server)
- Provision script path correctness
- Environment variable passing
```

**Expected findings:** Verify syntax and resource allocation

**Action:** Fix any issues found

---

### Task 28: Create provision.sh header and arg parsing

**Tool:** local-code

**Files:**
- Create: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Create test/vagrant/provision.sh with:

1. Shebang and strict mode
2. Parse environment variables:
   - TEST_DISTRO (default to "unknown")
   - TEST_ROLE (default to "server")
3. Log function: log() for timestamped messages
4. Print header: "Provisioning $TEST_DISTRO for $TEST_ROLE testing"
5. Main function structure (empty for now):
   - setup_machines_repo()
   - run_installation()
   - verify_installation()
   - test_idempotency()
   - collect_results()

~30 lines, skeleton only
```

**Expected output:** Provision script structure

**Validation:** `bash -n test/vagrant/provision.sh`

---

### Task 29: Implement setup_machines_repo() function

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Implement setup_machines_repo() in provision.sh:

- Copy /vagrant/../../ to /home/vagrant/machines (repo is 2 dirs up from Vagrantfile)
- Set ownership to vagrant:vagrant
- Verify repo copied successfully
- Log each step
- Return 0 on success, 1 on failure

~15 lines
```

**Expected output:** Repo setup function

**Validation:** Call function in VM, verify /home/vagrant/machines exists

---

### Task 30: Implement run_installation() function

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Implement run_installation() in provision.sh:

- cd /home/vagrant/machines
- Run: ./install.sh --role $TEST_ROLE 2>&1 | tee /tmp/install.log
- Capture exit code
- If failure: log error, show last 20 lines of log, return 1
- If success: log success, return 0

~15 lines
```

**Expected output:** Installation executor function

**Validation:** Check log file created, exit code captured

---

### Task 31: Implement verify_installation() function (part 1)

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Implement verify_installation() in provision.sh (basic checks):

- Verify core commands exist: git, zsh, bat, cargo
- Use command -v for each
- Count successes
- Log results
- Return 0 if all found, 1 if any missing

~20 lines
```

**Expected output:** Package verification function

**Validation:** Run in VM, check exit code

---

### Task 32: Implement verify_installation() function (part 2)

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Extend verify_installation() in provision.sh:

For workstation role only (if TEST_ROLE == workstation):
- Check if GDM session file exists: /usr/share/wayland-sessions/hyprland.desktop
- If missing: log warning (not error, Hyprland might not be installed)
- Check systemd services enabled (example: check one service)

~15 additional lines
```

**Expected output:** Desktop-specific verification

**Validation:** Run with TEST_ROLE=workstation

---

### Task 33: Implement test_idempotency() function

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Implement test_idempotency() in provision.sh:

- Log: "Testing idempotency (second run)..."
- Run: ./install.sh --role $TEST_ROLE 2>&1 | tee /tmp/install-second.log
- Capture exit code
- If failure: log error, return 1
- If success: log "Idempotency verified", return 0

~15 lines
```

**Expected output:** Idempotency test function

**Validation:** Second run should skip already-installed packages

---

### Task 34: Implement collect_results() function

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Implement collect_results() in provision.sh:

- Create results directory: /vagrant/test-results/full/$TEST_DISTRO
- Copy logs: /tmp/install*.log to results dir
- Generate package list:
  - Debian/Ubuntu: dpkg -l > packages.txt
  - Arch: pacman -Q > packages.txt
- Generate service list: systemctl list-units --state=running > services.txt
- Log collection complete
- Return 0

~20 lines
```

**Expected output:** Results collection function

**Validation:** Check files created in test-results/

---

### Task 35: Complete provision.sh main() function

**Tool:** local-code

**Files:**
- Modify: `test/vagrant/provision.sh`

**Prompt for local-code:**
```
Implement main() in provision.sh:

- Call functions in order:
  1. setup_machines_repo || exit 1
  2. run_installation || exit 1
  3. verify_installation || exit 1
  4. test_idempotency || exit 1
  5. collect_results || exit 1
- Log success at end
- Exit 0

~10 lines
Make script executable
```

**Expected output:** Complete working provision script

**Validation:** `chmod +x test/vagrant/provision.sh`

---

### CHECKPOINT 4: Review Vagrant infrastructure

**Tool:** local-review

**Files:**
- Review: `test/vagrant/Vagrantfile`
- Review: `test/vagrant/provision.sh`

**Prompt for local-review:**
```
Review Vagrant infrastructure for:
- Path traversal issues (/vagrant/../..)
- Command injection in provision script
- Missing error handling in provision functions
- File ownership problems (vagrant user)
- Log file permissions
- Exit code propagation
- Environment variable validation
```

**Expected findings:** Security and error handling issues

**Action:** Fix issues before testing

---

### Task 36: Test Vagrant VM manually (Ubuntu)

**Tool:** bash (manual execution)

**Commands:**
```bash
cd test/vagrant
vagrant up ubuntu24
# Wait for provisioning to complete
vagrant ssh ubuntu24 -c "ls /home/vagrant/machines"
vagrant destroy -f ubuntu24
```

**Expected:** VM boots, provisions successfully, machines repo present, destroys cleanly

**Validation:** Check test-results/full/ubuntu24/ has logs

**Commit:**
```bash
git add test/vagrant/Vagrantfile test/vagrant/provision.sh
git commit -m "feat: add Vagrant full integration testing

- Multi-machine Vagrantfile (Ubuntu, Debian, Arch)
- Provision script with installation + verification
- Idempotency testing (run installer twice)
- Results collection to test-results/full/
- 10-15 min per distro"
```

---

## Phase 5: Makefile Full Test Interface

### Task 37: Add check-vagrant helper to Makefile

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add to Makefile:

check-vagrant target:
- Check if vagrant command exists
- If missing: print error with installation instructions
- Exit 2 if missing
- Log success if present

~10 lines
```

**Expected output:** Vagrant prerequisite check

**Validation:** `make check-vagrant`

---

### Task 38: Add test-full-ubuntu24 target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-full-ubuntu24 target to Makefile:

- Depends on: check-vagrant
- Prints: "Testing Ubuntu 24.04 (Vagrant)..."
- Runs: cd $(TEST_DIR)/vagrant && vagrant up ubuntu24
- On success: vagrant destroy -f ubuntu24, print green "✓ PASS"
- On failure: print red "✗ FAIL", keep VM for debugging, exit 1
- Show execution time

~15 lines
```

**Expected output:** Ubuntu full test target

**Validation:** `make test-full-ubuntu24`

---

### Task 39: Add test-full-debian12 target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-full-debian12 target to Makefile:
- Same pattern as ubuntu24
- Changes: VM name debian12
- ~12 lines
```

**Expected output:** Debian full test target

**Validation:** `make test-full-debian12`

---

### Task 40: Add test-full-arch target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-full-arch target to Makefile:
- Same pattern as ubuntu24/debian12
- Changes: VM name arch
- ~12 lines
```

**Expected output:** Arch full test target

**Validation:** `make test-full-arch`

---

### Task 41: Add test-full aggregate target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-full target to Makefile:
- Depends on: test-full-ubuntu24 test-full-debian12 test-full-arch
- Prints header: "Running full integration tests..."
- Prints summary: "Full tests: X/3 passed"
- Uses color codes

~8 lines
```

**Expected output:** Aggregate full test target

**Validation:** `make test-full` (WARNING: takes 30-45 min)

---

### Task 42: Add combined test-ubuntu24 target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-ubuntu24 target to Makefile:
- Depends on: test-quick-ubuntu24 test-full-ubuntu24
- Prints: "Running quick + full tests for Ubuntu 24.04"
- ~5 lines
```

**Expected output:** Combined quick+full for Ubuntu

**Validation:** `make test-ubuntu24`

---

### Task 43: Add combined targets for Debian and Arch

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add to Makefile:

test-debian12 target:
- Depends on: test-quick-debian12 test-full-debian12

test-arch target:
- Depends on: test-quick-arch test-full-arch

~10 lines total
```

**Expected output:** Combined targets for all distros

**Validation:** `make test-debian12`, `make test-arch`

---

### Task 44: Add test-shell debugging targets

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add to Makefile:

test-shell-ubuntu24, test-shell-debian12, test-shell-arch targets:
- Each: cd $(TEST_DIR)/vagrant && vagrant up <vm> && vagrant ssh <vm>
- Keeps VM running for debugging
- ~12 lines total (3 targets)
```

**Expected output:** Interactive debugging targets

**Validation:** `make test-shell-ubuntu24` (should SSH into VM)

---

### Task 45: Add test-clean target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-clean target to Makefile:

- Remove Docker images: machines-test:*
- Destroy all Vagrant VMs: cd test/vagrant && vagrant destroy -f
- Remove test-results directory
- Print cleanup summary
- ~12 lines
```

**Expected output:** Cleanup target

**Validation:** `make test-clean`

---

### Task 46: Add test-all aggregate target

**Tool:** local-code

**Files:**
- Modify: `Makefile`

**Prompt for local-code:**
```
Add test-all target to Makefile:
- Depends on: test-quick test-full
- Prints: "Running ALL tests (quick + full)"
- Final summary with total pass/fail
- ~8 lines
```

**Expected output:** Master test target

**Validation:** `make test-all` (takes 1 hour+)

---

### CHECKPOINT 5: Final Makefile review

**Tool:** local-review

**Files:**
- Review: `Makefile`

**Prompt for local-review:**
```
Review complete Makefile for:
- Missing .PHONY declarations
- Shell escaping issues
- Incorrect target dependencies
- Error handling (|| exit 1)
- Color code consistency
- Path handling ($(TEST_DIR))
- Missing prerequisites checks
```

**Expected findings:** Any missing safety checks or declarations

**Action:** Fix issues

**Commit:**
```bash
git add Makefile
git commit -m "feat: add Makefile full test and debugging targets

- test-full-* targets for Vagrant VMs
- test-*-shell for interactive debugging
- test-clean for infrastructure cleanup
- test-all for complete test suite
- Combined test-<distro> targets (quick + full)"
```

---

## Phase 6: Documentation and Final Testing

### Task 47: Create test-results .gitignore

**Tool:** bash (direct execution)

**Commands:**
```bash
cat > test-results/.gitignore << 'EOF'
# Ignore all test results
*

# But keep directory structure
!.gitignore
EOF

git add test-results/.gitignore
git commit -m "chore: ignore test results directory"
```

**Validation:** `git status` should not show test-results contents

---

### Task 48: Create TESTING.md documentation

**Tool:** local-doc

**Files:**
- Create: `TESTING.md`

**Prompt for local-doc:**
```
Create TESTING.md with sections:

1. Overview - what the test infrastructure does
2. Prerequisites - Docker, Vagrant, libvirt installation
3. Quick Start - common make commands
4. Test Types - quick vs full explanation
5. Distro Matrix - which distros are tested
6. Usage Examples - concrete examples for each scenario
7. Debugging - how to use test-shell-* targets
8. Troubleshooting - common issues and fixes

Keep it practical, under 200 lines, focused on usage not theory
```

**Expected output:** User-friendly testing documentation

**Validation:** `cat TESTING.md` and review

---

### Task 49: Update README.md with testing section

**Tool:** local-code

**Files:**
- Modify: `README.md`

**Prompt for local-code:**
```
Add Testing section to README.md after "How" section:

## Testing

This repository includes automated testing infrastructure for validating
bootstrap scripts across multiple distributions.

### Quick validation (2-5 minutes)
make test-quick

### Full integration testing (30-45 minutes)
make test-full

### Test specific distro
make test-ubuntu24     # Quick + Full
make test-debian12     # Quick + Full

See TESTING.md for detailed usage.

~15 lines total
```

**Expected output:** README updated with testing info

**Validation:** `cat README.md | grep -A 10 Testing`

---

### Task 50: Run full test suite verification

**Tool:** bash (manual execution, LONG RUNNING)

**Commands:**
```bash
# Quick tests (should be fast)
make test-quick

# Test one full VM (sample)
make test-full-ubuntu24

# Verify results collected
ls -la test-results/quick/
ls -la test-results/full/ubuntu24/

# Verify cleanup works
make test-clean
```

**Expected:** All tests pass, results collected, cleanup successful

**Validation:** Exit code 0, no errors in logs

**Commit:**
```bash
git add TESTING.md README.md
git commit -m "docs: add testing documentation

- TESTING.md with comprehensive usage guide
- README.md updated with testing section
- Prerequisites and troubleshooting included"
```

---

## Final Verification Checklist

**Manual verification before merging:**

- [ ] All Dockerfiles build successfully
- [ ] test-quick works for all 3 distros
- [ ] At least one test-full VM boots and provisions
- [ ] test-shell-* allows interactive debugging
- [ ] test-clean removes all infrastructure
- [ ] Documentation is clear and accurate
- [ ] No secrets or credentials in committed files
- [ ] .gitignore properly excludes test-results

**Final commit:**
```bash
git log --oneline  # Review all commits
git diff main..feature/vm-testing-infrastructure  # Review all changes
# If all good, ready to merge
```

---

## Execution Notes

**Estimated total time:**
- Phase 1-3 (Docker + Makefile): ~2 hours
- Phase 4-5 (Vagrant + Makefile): ~2 hours
- Phase 6 (Docs + Testing): ~1 hour
- **Total: ~5 hours of implementation**

**Ollama tasks:** ~40 micro-tasks (30-60s each) = ~30 minutes of generation
**Claude checkpoints:** 5 reviews (~5 minutes each) = ~25 minutes
**Manual testing:** ~3 hours (includes VM boot times)

**Dependencies:**
- Docker installed and running
- Vagrant + libvirt installed
- 16GB+ RAM recommended for parallel VMs
- 20GB+ disk space for boxes

---

**End of Implementation Plan**
