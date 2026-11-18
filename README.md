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
│   ├── ai.sh             #   rocm + ollama + llama-cpp + llama-swap
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

Install only a specific package or recipe, skipping bootstrap, core packages,
role, and host extras entirely:

```bash
./install.sh --only sbx
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
| `workstation` | core + shell + cli + ai-stack + desktop-apps + wayland + nautilus + sharing + neovim + tmux + opencode + pi + pi-extensions + docker | Desktop environment lives in `host_extras` (e.g. niri-stack). `ai-stack` also pulls host ROCm on AMD machines (skipped when no AMD GPU is present). See [Pi extensions](#pi-extensions) for what pi-extensions installs. |
| `homelab` | server + net-tools + iproute2 + sops | Server hardening with secrets/network tools |
| `gaming` | core + shell + dev + gaming-desktop-apps + sharing + vulkan + nvidia-driver + steam + steam-remote-play-firewall + gaming-stack + vr-stack | Multilib auto-enabled on Arch. Vulkan ICD per GPU (AMD/Intel/NVIDIA), plus `lib32-nvidia-utils` for 32-bit Steam/Proton. VR stack is AUR-only. See [VR / Steam Link](#vr--steam-link) for what's automated vs. manual. |

`install_core_packages` runs once at the top of `main()`, before the role —
roles compose by calling sub-installers, not by re-running core.

---

## VR / Steam Link

The `gaming` role targets streaming VR to a standalone headset (Meta Quest,
Pico) via **Steam Link** — the game runs on the PC and SteamVR streams frames
to the headset over the LAN. Reference setup: CachyOS + Niri/Wayland + Meta
Quest + Half-Life: Alyx.

### What the role automates

| Piece | Handled by |
|---|---|
| Steam client | `installers/steam.sh` |
| Vulkan runtime + 32-bit ICD (AMD/Intel/NVIDIA) | `installers/vulkan.sh` (+ `lib32-nvidia-utils` from `nvidia-driver.sh`) |
| Headset discovery (mDNS / `.local`) | `packages/sharing.sh` — avahi + nss-mdns |
| OpenVR→OpenXR + wireless runtime | `installers/vr-stack.sh` — opencomposite, xrizer, wivrn (AUR-only) |
| Firewall ports for Steam Link / Remote Play / VR streaming | `installers/steam-remote-play-firewall.sh` |

### Firewall ports

Steam Link, Remote Play, and VR streaming need inbound ports open. On a box
with **no firewall these are already reachable** — the gaming role does not pull
in the security stack, so it does not install or enable `ufw`. But if `ufw` *is*
present (e.g. installed separately), its default `deny incoming` silently drops
the headset's packets and the PC shows up greyed-out in Steam Link.

`installers/steam-remote-play-firewall.sh` closes that gap. It runs only when
`ufw` is already installed, and adds LAN-scoped allow rules (never global):

| Ports | Proto | Purpose |
|---|---|---|
| 27031, 27036 | UDP | Remote Play discovery + streaming |
| 27036, 27037 | TCP | Remote Play |
| 10400, 10401 | UDP | VR streaming (Steam Link → SteamVR) |

The LAN subnet is auto-detected from the default-route interface. Override it
when detection is wrong or the box has multiple NICs:

```bash
STEAM_LAN_SUBNET=192.168.128.0/23 ./install.sh --role gaming
```

Rules are added with `ufw allow` (idempotent — duplicates are skipped) and are
refused for non-private subnets as a safety guard. Verify with
`sudo ufw status numbered`.

### Manual steps (not automatable)

- **Steam Link on the headset** — install the Steam Link app on the Quest/Pico
  from its store; it is not a PC package.
- **Enable Remote Play** — Steam → Settings → Remote Play → Enable Remote Play.
- **In-Steam content** — install SteamVR and the VR title (e.g. Half-Life:
  Alyx) from within Steam.
- **SteamVR on Wayland (Niri/wlroots)** — `vrmonitor` can crash trying to load a
  Wayland Qt plugin. Set a per-game launch option (stored in Steam's own config,
  so the bootstrap can't set it) under SteamVR → Properties → Launch Options:

  ```bash
  QT_QPA_PLATFORM=xcb %command%
  ```

  Stronger fallback if it still crashes: `WAYLAND_DISPLAY= QT_QPA_PLATFORM=xcb %command%`.
- **Network** — wire the PC by Ethernet, keep the headset on 5/6 GHz Wi-Fi on
  the same subnet, and avoid guest/client/AP isolation. VPN or virtual
  interfaces (WireGuard, Tailscale, ZeroTier) can make VRLink bind the wrong
  NIC — disable them while streaming if the PC won't connect.

### Quick checks

```bash
# Steam is listening on the streaming ports
ss -lntup | grep -E ':(27031|27036|27037|10400|10401)\b'

# UFW rules applied
sudo ufw status numbered
```

## Pi extensions

The `workstation` role installs [Pi](https://github.com/earendil-works/pi) — a
minimal, extensible coding-agent CLI — plus a curated set of community
extensions that close the capability gap with [Oh My Pi](https://omp.sh)
(omp), which ships LSP, an MCP client, subagents, a TODO tool, plan mode, and
Docker sandboxing built in. Pi's core has none of that; it gets them through
`pi install npm:<pkg>` instead, which is Pi's own package manager, not the OS
one this repo otherwise wraps.

### What `pi-extensions` installs

| Capability | Extension | Matches omp's |
|---|---|---|
| LSP, lint, format | `pi-lens` | built-in `lsp` tool |
| MCP client | `pi-mcp-adapter` | built-in MCP support |
| Subagents | `@tintinweb/pi-subagents` | `task`/`agents` |
| TODO | `@juicesharp/rpiv-todo` | built-in todo overlay |
| Structured ask-user | `@juicesharp/rpiv-ask-user-question` | built-in ask tool |
| Plan mode | `@narumitw/pi-plan-mode` | `--plan`/`--plan-yolo` |
| Docker sandboxing | `@christianmoesl/pi-sbx` | `sbx-sandbox` skill |

The `sbx` CLI itself (that `pi-sbx` talks to) is installed and kept updated
separately, by `installers/sbx.sh` as part of the workstation role.

Those seven are installed unconditionally — they mirror something omp ships
by default, so there's no real reason not to have them.

Five more are prompted for interactively (skipped with instructions in
non-interactive/dry-run runs) — either newer/single-maintainer with no long
track record, or a genuine enhancement omp doesn't ship either:

| Capability | Extension | Note |
|---|---|---|
| Python execution | `@nteract/pi` | Persistent notebook-backed Python REPL; also installs the separate `runtimed` daemon it shells out to (native binary, not an npm dependency) |
| ACP server | `pi-acp` | Bridges Pi to ACP editors (Zed, …) over stdio JSON-RPC |
| Long-term memory | `pi-memory` | qmd-powered semantic search across sessions; not an omp built-in, but 34k downloads/month |
| Session handoff/search | `pi-sessions` | Search, indexing, auto-titling, cross-session handoff/messaging; partial answer to omp's collab/share, modest adoption |
| Lazy extension loading | `pi-lazy-extensions` | Loads other extensions on demand instead of eagerly; worth it once you're running this many. Same author as `pi-web-access`/`pi-mcp-adapter` |

Pi extensions run with full system access — review the source before
accepting any prompt, same trust bar as anything installed elsewhere in
this repo.

Considered and deliberately left out (not in the script; install manually if
wanted):

| Extension | Why not |
|---|---|
| `pi-browser-cdp-extension` | 79 downloads/month; redundant with the `chrome-devtools-mcp` path `pi-mcp-adapter` already exposes |
| `@nicknisi/pi-handoff` | Duplicates this ecosystem's own `prepare-handoff` skill (aic-packages) at the prompt layer; personal-scoped, 386 downloads/month |
| `@arhen/pi-core-skill-tool` | A system-prompt token-savings tweak (skill catalog → lazy tool), not a capability gap; 461 downloads/month |
| `pi-web-access` | Already installed on this machine (web search/fetch/PDF/video) — predates this script, nothing to add |
| `@pi-kaush/pi-better-read-edit` | **Confirmed broken in practice**: registers its own `read`/`edit` tools, which fatally conflicts with `pi-sbx` (core, above) wrapping the same two tool names — Pi refuses to start with both installed (`Tool "read" conflicts with ...`). `pi-sbx` is the higher-value, higher-adoption, core-parity match (omp's Docker sandboxing) and won the tiebreak; don't reinstall `pi-better-read-edit` without dropping `pi-sbx` first |

### Manual steps (not automatable)

- **Browser automation** (`chrome-devtools-mcp`) is wired by a separate
  `aic-packages` MCP config, not by this repo. `pi-extensions.sh` checks that
  Docker and `runtimed` are present; it prints a reminder to verify
  `~/.pi/agent/mcp.json` and run `aic sync` there if the entry is missing.
- **Project trust** — Pi's `defaultProjectTrust: ask` blocks even
  non-interactive `pi -p` runs on new projects until you accept the prompt
  once, interactively.
- **ACP client wiring** (Zed, etc.) — editor-side config; not this repo's job.

### Startup warnings that are expected, not bugs

- `No sbx sandbox is active for <dir>. Tool calls will run on the host.` —
  `pi-sbx` only routes tools through Docker sbx once you run
  `sbx create --template <image> shell .` in that specific project; it isn't,
  and shouldn't be, active everywhere by default. `pi`/`omp` also aren't
  native `sbx create` agents — see `aic-packages`' `sbx-sandbox` skill for the
  (experimental) custom-template path. The `sbx` binary itself is installed
  and updated by `installers/sbx.sh` (workstation role), independently of
  the `pi-sbx` extension.
- `Anthropic subscription auth is active. Third-party harness usage draws
  from extra usage...` — has nothing to do with any extension here. It's Pi
  telling you that running a Claude subscription (Pro/Max OAuth) through a
  third-party harness like Pi bills per-token against extra usage rather than
  the subscription's flat quota — a fact about your auth method, not this
  repo. Silence it from Pi's own `/settings` if you don't want the reminder.

### Re-running

```bash
./install.sh --role workstation --packages "pi, pi-extensions"
```

Both installers are idempotent: already-installed extensions are detected via
`~/.pi/agent/settings.json` and skipped.

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
