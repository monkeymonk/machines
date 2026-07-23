# machines

A small, opinionated collection of scripts to **bootstrap a Linux system** the way
I like it.

This repository is intentionally **separate from my dotfiles and secretfiles**,
which live in bare Git repositories. `machines` focuses on _getting a system
ready_; dotfiles and secretfiles focus on _configuring the user environment_.

Think of this repo as the missing step between a fresh OS install and a usable,
familiar machine.

---

## Why

I use a **bare Git repository** for my dotfiles, which works great once a system already has:

- a package manager set up
- core tools installed (git, curl, zsh, etc.)
- sane defaults and dependencies available

`machines` exists to solve everything _before_ that.

Goals:

- Work across **multiple distributions** (Arch, CachyOS, Manjaro, EndeavourOS,
  Debian, Ubuntu, macOS)
- Be **idempotent** (safe to re-run)
- Be **readable and boring**, not clever
- Keep distro-specific logic isolated
- Stay small enough to understand months later

This is not a full distro installer or a replacement for tools like Nix or
Ansible — it's a **personal, pragmatic bootstrap kit**.

---

## What

`machines` handles:

- Detecting the current distribution (Linux/macOS)
- Installing core system packages
- Installing optional groups (dev tools, desktop apps, server tools…)
- Handling special installers that don't fit normal package managers (AUR, .deb
  from upstream, build-from-source, etc.)
- Preparing the system so my bare dotfiles repo can be used immediately

It does **not**:

- Manage dotfiles directly
- Replace a configuration manager
- Make irreversible system changes without asking

---

## How

### Location

The repo lives at:

```bash
~/machines
```

---

### Structure

```text
machines/
├── install.sh            # main entry point
├── test.sh               # lint + syntax + dry-run checks
├── Makefile              # convenience targets for the test suite
├── bootstrap/            # distro-specific system prep
│   ├── arch.sh           #   covers arch / cachyos / manjaro / endeavouros
│   ├── ubuntu.sh         #   covers ubuntu / debian
│   └── macos.sh
├── lib/                  # shared helpers
│   ├── log.sh            #   logging
│   ├── os.sh             #   distro detection + capability gates
│   ├── pkg.sh            #   package-manager abstraction + AUR + apt repo
│   └── sysd.sh           #   systemd / sudoers / privileged-file helpers
├── packages/             # logical package groups
│   ├── core.sh           #   git, curl, build tools, archive tools, …
│   ├── cli.sh            #   fzf, ripgrep, fd, bat, eza, jq, mise, uv, atuin, …
│   ├── dev.sh            #   slot for extra dev-only packages
│   ├── shell.sh          #   zsh + oh-my-zsh
│   ├── ai.sh             #   ollama + llama-cpp + llama-swap
│   ├── desktop-apps.sh   #   firefox, filezilla, mpv (gui-capable hosts)
│   ├── wayland.sh        #   cliphist, wl-clipboard, grim, slurp
│   ├── nautilus.sh       #   nautilus + plugins
│   ├── sharing.sh        #   avahi + nss-mdns (mDNS / .local discovery)
│   ├── gaming.sh         #   gamemode, mangohud, protonup-qt (+lib32)
│   ├── security.sh       #   fail2ban, ufw, openssh, auditd, logwatch
│   ├── server-tools.sh   #   ncdu, rsync
│   └── homelab.sh        #   net-tools, iproute2, sops
├── installers/           # special-case installers (one per tool)
│   └── <tool>.sh         #   AUR-only, third-party apt repo, source build, etc.
├── hosts/                # host-specific overrides
│   └── <hostname>.sh     #   auto-loaded by hostname; sets ROLE + host_extras
├── roles/                # role presets
│   ├── server.sh
│   ├── workstation.sh
│   ├── gaming.sh
│   └── homelab.sh
└── test/                 # docker + vagrant test infrastructure
    ├── docker/
    ├── vagrant/
    └── lib/
```

Design rules:

- **`packages/` describe intent** (what I want)
- **`bootstrap/` handles distro reality** (how to get there)
- **`installers/` are escape hatches** for weird cases
- Logic lives in `lib/`, not copy-pasted everywhere

---

### Usage

Clone the repository:

```bash
git clone <repo-url> ~/machines
cd ~/machines
```

Run the installer:

```bash
./install.sh --role server         # Lean security-focused server
./install.sh --role workstation    # Full dev environment + AI stack
./install.sh --role homelab        # Server + sops + networking tools
./install.sh --role gaming         # Steam + nvidia drivers + desktop apps
```

Use `--dry-run` to preview actions without installing.

Install extra packages on demand:

```bash
./install.sh --packages "htop, jq, bat"
```

Add host-specific overrides by creating `hosts/<hostname>.sh`. The file is
auto-loaded based on the current hostname. It can set `ROLE` and define a
`host_extras()` function that runs after the role completes. Gate
role-specific extras on `$ROLE` so a `--role server` install on a workstation
host doesn't pull in desktop packages — see `hosts/example.sh`.

Once `install.sh` finishes, the system is ready for:

- cloning / enabling the bare dotfiles repository
- applying secretfiles from a separate bare repository
- day-to-day usage with minimal manual setup

---

## Roles

| Role | Includes | Notes |
|---|---|---|
| `server` | core + security + server-tools + docker + neovim | fail2ban, ufw, openssh, auditd, logwatch |
| `workstation` | core + shell + cli + ai-stack + desktop-apps + wayland + nautilus + sharing + neovim + tmux + opencode + docker | Desktop environment lives in `host_extras` (e.g. niri-stack) |
| `homelab` | server + net-tools + iproute2 + sops | Server hardening with secrets/network tools |
| `gaming` | core + shell + dev + gaming-desktop-apps + sharing + vulkan + steam + gaming-stack + vr-stack | Multilib auto-enabled on Arch. Vulkan ICD per GPU (AMD/Intel/NVIDIA). VR stack is AUR-only. |

`install_core_packages` runs once at the top of `main()`, before the role —
roles compose by calling sub-installers, not by re-running core.

---

## Cross-distro behaviour

Packages are resolved through `install_package_with_mapping` in `lib/pkg.sh`,
which accepts entries like:

```bash
"build-essential,arch:base-devel"
"7zip,arch:p7zip,debian:p7zip-full"
"poppler-utils,arch:poppler"
```

Resolution per distro family:

- **Arch family** (arch / cachyos / manjaro / endeavouros) — `arch:` override
  uses pacman; `aur:` override uses paru. With no override, the auto path
  tries pacman first and falls back to AUR. Paru is bootstrapped from
  `paru-bin`; if that fails its smoke test (e.g. libalpm soname mismatch),
  it's rebuilt from source.
- **Debian/Ubuntu** — `ubuntu:` override beats `debian:` on Ubuntu;
  `debian:` is the fallback for both. Always apt.
- **macOS** — `macos-cask:` uses brew --cask; `macos:` uses brew. Always brew.

Capability gates (also in `lib/os.sh`) skip GUI/Wayland installers on headless
hosts and containers automatically.

---

## Testing

Two layers, both invoked through the `Makefile`:

- **`test.sh` — lint** (always fast, runs locally): bash syntax check on every
  script, source-import check for the lib/packages stack, and a `--dry-run`
  for the default role. Required to pass before any container/VM test.
- **Docker quick tests** (~2-5 min/distro): build a minimal image, run
  `./test.sh`, then `./install.sh --role X --dry-run`, then run the install
  twice (second pass exercises idempotency), then assert `git zsh cargo
  ollama` are on PATH. Three matrices: Ubuntu 24.04 / Debian 12 / Arch.
- **Vagrant full tests** (~10-20 min/distro, optional): run the full install
  in a real VM with systemd, including service enablement and the second-run
  idempotency check. Needs Vagrant + libvirt.

### Running locally

```bash
./test.sh                  # lint + dry-run only

make test-quick            # docker quick tests for all 3 distros
make test-quick-ubuntu24   # one distro
make test-quick-debian12
make test-quick-arch

make test-full             # vagrant full tests for all 3 distros
make test-shell-ubuntu24   # interactive SSH into a vagrant VM for debugging

make test-clean            # remove built images, vagrant boxes, and results
```

### Test environment knobs

- `OLLAMA_SKIP_MODELS=true` — skip the interactive model-pull menu in
  `installers/ollama.sh`. Always set inside the test runner.
- `SKIP_CARGO_PACKAGES=true` — skip `cargo install` in `packages/core.sh`
  (those crates compile slowly and are non-critical for verification). Always
  set inside the test runner.
- `DRY_RUN=true` — set automatically by `--dry-run`.

### Prerequisites

```bash
# Docker (quick tests)
sudo pacman -S docker docker-buildx       # arch
sudo apt install docker.io docker-buildx  # debian/ubuntu
sudo usermod -aG docker $USER && newgrp docker

# Vagrant + libvirt (full tests)
sudo pacman -S vagrant qemu libvirt       # arch
sudo apt install vagrant qemu-kvm libvirt-daemon-system libvirt-clients  # debian/ubuntu
vagrant plugin install vagrant-libvirt
sudo usermod -aG libvirt $USER && newgrp libvirt
```

The Docker test runner exports `DOCKER_BUILDKIT=0` so it works on hosts where
the buildx component isn't installed. Detailed troubleshooting and the full
distro/role matrix live in [TESTING.md](TESTING.md).

---

## Philosophy

- **Declarative over clever** – scripts should read like documentation
- **Re-runnable by default** – no one-shot assumptions
- **Explicit over implicit** – nothing happens silently
- **Personal, not universal** – this is for _my_ systems

If something feels like it belongs in dotfiles, it probably doesn't belong here.
If something is needed before dotfiles can even run, it probably belongs here.

---

## Evolving the Repo

The model is simple: add tools and apps as the need arises, and keep each
addition small and explicit.

When adding a new tool:

1. Try a clean cross-distro mapping in a `packages/*.sh` group first.
2. If a tool needs apt-repo-add, build-from-source, AUR-only, or other
   special handling, write `installers/<tool>.sh` and call it via
   `install_package <tool>`.
3. Wire it into a role or package group.
4. Keep distro logic in helpers or the installer, not in the roles.

This keeps the scripts boring, repeatable, and easy to evolve over time.

---

**Fresh system → `machines` → dotfiles → secretfiles → done.**
