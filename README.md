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

- Work across **multiple distributions** (Arch, Ubuntu, etc.)
- Be **idempotent** (safe to re-run)
- Be **readable and boring**, not clever
- Keep distro-specific logic isolated
- Stay small enough to understand months later

This is not a full distro installer or a replacement for tools like Nix or
Ansible — it’s a **personal, pragmatic bootstrap kit**.

---

## What

`machines` handles:

- Detecting the current distribution (Linux/macOS)
- Installing core system packages
- Installing optional groups (dev tools, desktop apps, server tools…)
- Handling special installers that don’t fit normal package managers
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

This keeps it clearly separated from my bare dotfiles repo (which typically
lives at `$HOME` with a different Git setup).

---

### Structure

High-level layout:

```text
machines/
├── install.sh          # main entry point
├── test.sh             # lint + syntax + dry-run checks
├── bootstrap/          # distro-specific system prep
│   ├── arch.sh
│   ├── ubuntu.sh
│   └── macos.sh
├── lib/                # shared helpers
│   ├── os.sh           # OS / distro detection
│   ├── pkg.sh          # package manager abstraction
│   └── log.sh          # logging helpers
├── packages/           # logical package groups
│   ├── core.sh
│   ├── dev.sh
│   ├── shell.sh
│   ├── lazyvim.sh
│   ├── terminals.sh
│   └── ai.sh
├── installers/         # special-case installers
│   ├── neovim.sh
│   └── <tool>.sh
├── hosts/              # host-specific overrides
│   └── <hostname>.sh
└── roles/              # optional presets
    ├── workstation.sh
    ├── server.sh
    └── gaming.sh
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
./install.sh --role workstation
```

Use `--role server` or `--role gaming` to select other presets. Use
`--dry-run` to preview actions without installing.

Install extra packages on demand:

```bash
./install.sh --packages "htop, jq, bat"
```

Add host-specific overrides by creating `hosts/<hostname>.sh`. These scripts
run after the role completes and can call any helper (install_package, log_info,
etc.).

Run the test suite:

```bash
./test.sh
```

Once this finishes, the system should be ready for:

- cloning / enabling the bare dotfiles repository
- applying secretfiles from a separate bare repository
- day-to-day usage with minimal manual setup

---

## Philosophy

- **Declarative over clever** – scripts should read like documentation
- **Re-runnable by default** – no one-shot assumptions
- **Explicit over implicit** – nothing happens silently
- **Personal, not universal** – this is for _my_ systems

If something feels like it belongs in dotfiles, it probably doesn’t belong here.
If something is needed before dotfiles can even run, it probably belongs here.

---

## Evolving the Repo

The model is simple: add tools and apps as the need arises, and keep each
addition small and explicit.

When adding a new tool:

1. Create a new installer in `installers/<tool>.sh` if the package manager
   isn’t enough or you need special logic.
2. Wire it into a role or package group using `install_package <tool>`.
3. Prefer updating the role directly when it only applies to a single role.
4. Keep distro logic in helpers or the installer, not in the roles.

This keeps the scripts boring, repeatable, and easy to evolve over time.

---

## Future ideas (maybe)

- Minimal TUI / menu wrapper
- Expand test coverage in disposable containers

No rush. The goal is longevity, not features.

---

**Fresh system → `machines` → dotfiles → secretfiles → done.**
