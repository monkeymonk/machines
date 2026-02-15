# Hyprland Desktop Package Design

**Date:** 2026-01-29
**Status:** Approved Design
**Target:** Ubuntu 24.04 and Arch Linux

## Overview

This design describes a new package group `packages/hyprland.sh` that installs a complete Hyprland-based desktop environment, inspired by Omarchy's component choices. The package provides a full desktop replacement with tiling window management, modern Wayland tooling, and TUI-based system management tools.

## Goals

- Install a complete Hyprland desktop environment as a modular package
- Support both Ubuntu 24.04 (via PPAs/apt) and Arch Linux (via pacman)
- Integrate with GDM for session selection (appear as "Hyprland" alongside Ubuntu/GNOME)
- Follow existing `machines` patterns (idempotent, distro-aware, config-agnostic)
- Leave configuration to user's dotfiles repository

## Non-Goals

- Managing Hyprland configuration files (handled by dotfiles)
- Replacing existing roles (this is a package group, not a role)
- Building from source on Ubuntu (prefer PPAs/packages)
- Installing GPU drivers (user responsibility)
- Providing themes or visual configuration

## Component Stack

Based on Omarchy's setup, with adaptations for cross-distro compatibility:

### Core Desktop Components

| Component | Purpose | Notes |
|-----------|---------|-------|
| Hyprland | Tiling Wayland compositor | Via PPA on Ubuntu, pacman on Arch |
| Waybar | Status bar | Available in both distros |
| Mako | Notification daemon | Available in both distros |
| Hyprlock | Screen locker | Part of Hyprland ecosystem |
| SwayOSD | On-screen display | May need PPA on Ubuntu |
| Nautilus | File manager | GNOME's file manager |

### System Management (TUI)

| Tool | Purpose | Installation |
|------|---------|-------------|
| wiremix | Audio control (PipeWire) | Custom installer (cargo/source) |
| bluetui | Bluetooth management | Custom installer (cargo/source) |
| Impala | WiFi management (iwd) | Custom installer |

### Utilities

| Tool | Purpose |
|------|---------|
| Vicinae | Application launcher | Check if installed, optionally bundle |
| grim + slurp | Screenshot tools |
| wl-clipboard | Wayland clipboard utilities |
| cliphist | Clipboard history |
| hypridle | Idle management |
| nm-applet | NetworkManager system tray |
| blueman | Bluetooth system tray (GUI alternative) |
| polkit-gnome | Authentication agent |

### Already Installed (Not in Package)

User already has these from other packages:
- ghostty (terminal)
- neovim (editor)
- btop (system monitor)
- chromium (browser)

## Architecture

### File Structure

```
machines/
├── packages/
│   └── hyprland.sh          # Main package file (NEW)
├── installers/
│   ├── wiremix.sh           # Audio TUI installer (NEW)
│   ├── bluetui.sh           # Bluetooth TUI installer (NEW)
│   ├── impala.sh            # WiFi TUI installer (NEW)
│   ├── vicinae.sh           # Launcher installer (NEW, optional)
│   ├── hyprlock.sh          # Lock screen installer (NEW, if needed)
│   └── hypridle.sh          # Idle manager installer (NEW, if needed)
└── docs/
    └── plans/
        └── 2026-01-29-hyprland-design.md  # This document
```

### Package Structure

`packages/hyprland.sh` will follow existing patterns:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../lib/os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

install_hyprland_packages() {
    log_info "Installing Hyprland desktop environment..."

    # Install dependencies first
    install_hyprland_dependencies

    # Core Hyprland
    install_hyprland_core

    # Desktop components
    install_desktop_components

    # TUI system tools
    install_tui_tools

    # Utilities
    install_wayland_utilities

    # System integration
    setup_session_file

    log_info "Hyprland packages installed"
}
```

### Function Organization

Each installation category has its own function:

1. **`install_hyprland_dependencies()`**
   - Wayland protocols and libraries
   - PipeWire + wireplumber (audio)
   - bluez (Bluetooth stack)
   - NetworkManager + iwd (network)
   - GDM (display manager)
   - xdg-desktop-portal-hyprland

2. **`install_hyprland_core()`**
   - Hyprland compositor
   - Hyprlock (screen lock)
   - hypridle (idle management)

3. **`install_desktop_components()`**
   - Waybar (status bar)
   - Mako (notifications)
   - SwayOSD (OSD)
   - Nautilus (file manager)

4. **`install_tui_tools()`**
   - wiremix (audio)
   - bluetui (Bluetooth)
   - Impala (WiFi)

5. **`install_wayland_utilities()`**
   - grim + slurp (screenshots)
   - wl-clipboard + cliphist (clipboard)
   - nm-applet (network tray)
   - blueman (Bluetooth tray)
   - polkit-gnome (auth agent)
   - Vicinae (launcher, if needed)

6. **`setup_session_file()`**
   - Create GDM session file
   - Verify permissions

## Installation Approach

### Package Installation Methods

1. **Standard distro packages** (both Arch and Ubuntu):
   - Nautilus, grim, slurp, wl-clipboard
   - NetworkManager, nm-applet
   - bluez, blueman
   - polkit-gnome

2. **Distro-specific mapping** (different package names):
   ```bash
   install_package_with_mapping "package,arch:arch-name,ubuntu:ubuntu-name"
   ```

3. **PPA/AUR packages** (newer/specialized):
   - **Arch:** Available in official repos
   - **Ubuntu:** Requires PPAs (e.g., `ppa:hyprland-community/hyprland`)
   - Components: Hyprland, Hyprlock, hypridle, Waybar, Mako, SwayOSD

4. **Custom installers** (specialized tools):
   - TUI tools: wiremix, bluetui, Impala
   - May use cargo install or build from source
   - Fall back to custom installers when `install_package` can't find them

### Distro-Specific Implementation

**Hyprland Core:**
```bash
install_hyprland_core() {
    if is_arch; then
        install_package "hyprland"
        install_package "hyprlock"
        install_package "hypridle"
    elif is_ubuntu; then
        # Add PPA for Hyprland
        if ! grep -q "hyprland-community/hyprland" /etc/apt/sources.list.d/*.list 2>/dev/null; then
            log_info "Adding Hyprland PPA..."
            sudo add-apt-repository -y ppa:hyprland-community/hyprland
            sudo apt update
        fi
        install_package "hyprland"
        install_package "hyprlock"
        install_package "hypridle"
    fi
}
```

**Desktop Components:**
```bash
install_desktop_components() {
    install_package "waybar"
    install_package "mako"
    install_package "swayosd"
    install_package "nautilus"
}
```

**TUI Tools (via custom installers):**
```bash
install_tui_tools() {
    # Falls back to installers/*.sh if not in repos
    install_package "wiremix"
    install_package "bluetui"
    install_package "impala"
}
```

**Network Management:**
```bash
install_network_tools() {
    # NetworkManager (default, GUI-friendly)
    install_package_with_mapping "network-manager,arch:networkmanager"
    install_package "network-manager-applet"

    # iwd (for Impala)
    install_package "iwd"

    log_info "Both NetworkManager and iwd installed"
    log_info "Choose which to enable in your config/dotfiles"
    log_info "  systemctl enable NetworkManager  # OR"
    log_info "  systemctl enable iwd"
}
```

## Session Management

To integrate with GDM and make Hyprland appear as a session choice:

**Session File:** `/usr/share/wayland-sessions/hyprland.desktop`

```desktop
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
```

**Implementation:**
```bash
setup_session_file() {
    local session_dir="/usr/share/wayland-sessions"
    local session_file="${session_dir}/hyprland.desktop"

    # Check if GDM is installed
    if ! command -v gdm &> /dev/null; then
        log_warn "GDM not found, skipping session file creation"
        log_warn "Start Hyprland manually or install a display manager"
        return
    fi

    # Create session directory if needed
    if [[ ! -d "$session_dir" ]]; then
        sudo mkdir -p "$session_dir"
    fi

    # Create session file
    log_info "Creating Hyprland session file..."
    sudo tee "$session_file" > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF

    sudo chmod 644 "$session_file"
    log_info "Hyprland will appear in GDM session list"
}
```

## Dependencies

The package must ensure these dependencies are present:

### System Dependencies

1. **Wayland Infrastructure:**
   - wayland
   - wayland-protocols
   - xdg-desktop-portal
   - xdg-desktop-portal-hyprland (or -gtk fallback)

2. **Audio System (PipeWire):**
   - pipewire
   - wireplumber
   - pipewire-pulse (PulseAudio compatibility)
   - Note: Ubuntu 24.04 uses PipeWire by default

3. **Bluetooth:**
   - bluez
   - bluez-utils (Arch) / bluez-tools (Ubuntu)

4. **Network:**
   - NetworkManager + network-manager-applet
   - iwd (for Impala)
   - Both installed, user chooses which to enable

5. **Display Manager:**
   - GDM (Ubuntu's default)
   - Check and install if missing

6. **Graphics:**
   - mesa (OpenGL)
   - vulkan-loader
   - GPU drivers (not installed by this package)

7. **Build Tools (for custom installers):**
   - Rust/Cargo (from packages/core.sh via rustup)
   - git, make, cmake (if building from source)

### Dependency Installation

```bash
install_hyprland_dependencies() {
    log_info "Installing Hyprland dependencies..."

    # Wayland
    install_package_with_mapping "wayland,arch:wayland,ubuntu:libwayland-client0"
    install_package "wayland-protocols"
    install_package "xdg-desktop-portal"

    # Portal backend (try Hyprland-specific, fallback to GTK)
    if ! install_package "xdg-desktop-portal-hyprland"; then
        install_package "xdg-desktop-portal-gtk"
    fi

    # Audio (PipeWire)
    install_package "pipewire"
    install_package "wireplumber"
    install_package_with_mapping "pipewire-pulse,arch:pipewire-pulse,ubuntu:pipewire-pulse"

    # Bluetooth
    install_package "bluez"
    install_package_with_mapping "bluez-utils,arch:bluez-utils,ubuntu:bluez-tools"

    # Network
    install_network_tools

    # Display Manager
    if ! command -v gdm &> /dev/null; then
        log_info "Installing GDM display manager..."
        install_package_with_mapping "gdm,arch:gdm,ubuntu:gdm3"
    fi

    # Graphics
    install_package "mesa"
    install_package_with_mapping "vulkan-loader,arch:vulkan-icd-loader,ubuntu:libvulkan1"
}
```

## Custom Installers

Several tools will need custom installer scripts:

### `installers/wiremix.sh`

Audio control TUI for PipeWire.

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

# Check if already installed
if command -v wiremix &> /dev/null; then
    log_info "wiremix already installed"
    exit 0
fi

log_info "Installing wiremix..."

# Try package manager first
if is_arch; then
    # Check AUR or use cargo
    if command -v yay &> /dev/null; then
        yay -S --noconfirm wiremix || true
    fi
fi

# Fallback to cargo
if ! command -v wiremix &> /dev/null; then
    log_info "Building wiremix from cargo..."
    cargo install wiremix
fi

log_info "wiremix installed"
```

### `installers/bluetui.sh`

Bluetooth management TUI.

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

if command -v bluetui &> /dev/null; then
    log_info "bluetui already installed"
    exit 0
fi

log_info "Installing bluetui..."

# Try cargo install
if command -v cargo &> /dev/null; then
    cargo install bluetui
else
    log_error "Rust/Cargo required for bluetui installation"
    exit 1
fi

log_info "bluetui installed"
```

### `installers/impala.sh`

WiFi management TUI (requires iwd).

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"

if command -v impala &> /dev/null; then
    log_info "Impala already installed"
    exit 0
fi

log_info "Installing Impala..."

# Ensure iwd is installed
if ! command -v iwctl &> /dev/null; then
    log_warn "iwd not found, installing..."
    install_package "iwd"
fi

# Try package manager or build
if is_arch; then
    # Check AUR
    if command -v yay &> /dev/null; then
        yay -S --noconfirm impala-wifi || cargo install impala-wifi
    else
        cargo install impala-wifi
    fi
elif is_ubuntu; then
    # Build from source or cargo
    cargo install impala-wifi
fi

log_info "Impala installed"
log_info "Note: Impala requires iwd. To use:"
log_info "  sudo systemctl disable NetworkManager"
log_info "  sudo systemctl enable iwd"
```

### `installers/vicinae.sh`

Application launcher (optional, check if present first).

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

if command -v vicinae &> /dev/null; then
    log_info "Vicinae already installed"
    exit 0
fi

log_info "Installing Vicinae..."

# Installation method depends on how Vicinae is distributed
# Placeholder for actual installation logic
log_warn "Vicinae installation method TBD - check distribution method"
```

## Testing Strategy

### Automated Testing

1. **Syntax Validation:**
   ```bash
   shellcheck packages/hyprland.sh
   shellcheck installers/wiremix.sh installers/bluetui.sh installers/impala.sh
   ```

2. **Dry-run Testing:**
   ```bash
   ./install.sh --packages hyprland --dry-run
   ```
   - Verify all functions execute without errors
   - Check package names are valid
   - Ensure distro detection works

3. **Idempotency Testing:**
   ```bash
   ./install.sh --packages hyprland
   ./install.sh --packages hyprland  # Should skip installed packages
   ```

4. **Component Verification:**
   ```bash
   command -v Hyprland
   command -v waybar
   command -v mako
   command -v hyprlock
   command -v hypridle
   command -v wiremix
   command -v bluetui
   command -v impala
   ```

5. **Session File Validation:**
   ```bash
   test -f /usr/share/wayland-sessions/hyprland.desktop
   desktop-file-validate /usr/share/wayland-sessions/hyprland.desktop
   ```

### Manual Testing

1. **Installation Test:**
   - Run on fresh Ubuntu 24.04 and Arch systems
   - Verify all components install successfully
   - Check for errors or warnings

2. **Session Selection Test:**
   - Log out of current session
   - Verify "Hyprland" appears in GDM session list
   - Select Hyprland and log in
   - Verify Hyprland launches properly

3. **Functionality Test:**
   - Open terminal (ghostty)
   - Launch applications via Vicinae
   - Test Waybar visibility
   - Test notifications (Mako)
   - Test screen lock (Hyprlock)
   - Test TUI tools (wiremix, bluetui, Impala)

4. **Re-run Test:**
   - Run installation again
   - Verify idempotent behavior
   - No duplicate installations or errors

## Usage

### Installation Commands

**Fresh installation with Hyprland:**
```bash
# Minimal + Hyprland
./install.sh --packages hyprland

# Server role + Hyprland
./install.sh --role server --packages hyprland

# Workstation role + Hyprland
./install.sh --role workstation --packages hyprland

# Multiple package groups
./install.sh --packages "hyprland,dev,ai"

# Preview installation
./install.sh --packages hyprland --dry-run
```

**Re-running after updates:**
```bash
./install.sh --packages hyprland  # Safe to re-run
```

### Post-Installation

1. **Log out** of current session
2. At GDM login screen, **click the gear icon** (bottom right)
3. **Select "Hyprland"** from session list
4. **Log in** - Hyprland will start
5. **Configure** via your dotfiles (`~/.config/hypr/`)

### Verification

```bash
# Test installation
./test.sh

# Check installed components
command -v Hyprland waybar mako hyprlock hypridle

# Check TUI tools
command -v wiremix bluetui impala

# Check session file
cat /usr/share/wayland-sessions/hyprland.desktop
```

## Limitations and Considerations

### Known Limitations

1. **Ubuntu PPA Availability:**
   - Hyprland packages may lag behind Arch versions
   - PPAs are community-maintained, not official Ubuntu
   - Cutting-edge features may require source builds

2. **Network Management Choice:**
   - Both NetworkManager and iwd installed
   - User must choose and enable one via systemd
   - Both shouldn't run simultaneously
   - Impala requires iwd, GUI tools use NetworkManager

3. **Configuration Required:**
   - Package installs software only, no configs
   - User's dotfiles must provide:
     - `~/.config/hypr/hyprland.conf`
     - `~/.config/waybar/config`
     - `~/.config/mako/config`
     - Keybindings, autostart, window rules, etc.
   - Without dotfiles, Hyprland uses minimal defaults

4. **TUI Tool Installation:**
   - wiremix, bluetui, Impala may need building
   - Requires Rust/Cargo (installed via core packages)
   - First installation may be slower due to compilation

5. **Display Manager Dependency:**
   - Designed for GDM (Ubuntu's default)
   - Other DMs (SDDM, LightDM) need different session paths
   - Session file location varies by DM

6. **GPU Drivers:**
   - Not handled by this package
   - User must ensure proper drivers installed
   - Critical for Hyprland performance
   - Nvidia requires specific Hyprland build flags

### Network Management Configuration

Users must choose between NetworkManager and iwd:

**For NetworkManager (default, GUI-friendly):**
```bash
sudo systemctl enable NetworkManager
sudo systemctl disable iwd
```

**For iwd (required for Impala TUI):**
```bash
sudo systemctl disable NetworkManager
sudo systemctl enable iwd
```

Document this choice in dotfiles README.

## Future Enhancements

### Potential Additions

1. **Alternative Display Managers:**
   - Support SDDM session files
   - Support LightDM session files
   - Auto-detect installed DM

2. **Additional TUI Tools:**
   - lazygit (Git TUI) - Omarchy includes this
   - lazydocker (Docker TUI) - Omarchy includes this
   - fastfetch (system info) - Omarchy's "About" utility

3. **Theme Support:**
   - Optional Omarchy-inspired theme installation
   - System-level GTK/Qt themes
   - Separate from dotfiles configuration

4. **Uninstall Support:**
   - Script to remove Hyprland components
   - Restore to previous desktop environment
   - Clean removal of session files

5. **Configuration Starter Kit:**
   - Optional minimal Hyprland config
   - Helps users without existing dotfiles
   - Clearly separate from main package

## References

### Omarchy Resources
- [Omarchy Official Site](https://omarchy.org)
- [Omarchy GitHub](https://github.com/basecamp/omarchy)
- [The Omarchy Manual](https://learn.omacom.io/2/the-omarchy-manual)
- [Omarchy TUIs Documentation](https://learn.omacom.io/2/the-omarchy-manual/59/tuis)

### Component Documentation
- [Hyprland Wiki](https://wiki.hyprland.org)
- [Waybar Documentation](https://github.com/Alexays/Waybar/wiki)
- [Mako Notification Daemon](https://github.com/emersion/mako)
- [bluetuith GitHub](https://github.com/bluetuith-org/bluetuith)

### Ubuntu/Arch Resources
- [Hyprland on Ubuntu PPA](https://launchpad.net/~hyprland-community)
- [Arch Linux Hyprland Package](https://archlinux.org/packages/extra/x86_64/hyprland/)
- [Ubuntu 24.04 Release Notes](https://discourse.ubuntu.com/t/noble-numbat-release-notes/)

## Implementation Checklist

- [ ] Create `packages/hyprland.sh` with main installation logic
- [ ] Create `installers/wiremix.sh` for audio TUI
- [ ] Create `installers/bluetui.sh` for Bluetooth TUI
- [ ] Create `installers/impala.sh` for WiFi TUI
- [ ] Create `installers/vicinae.sh` for launcher (optional)
- [ ] Implement dependency installation function
- [ ] Implement Hyprland core installation (distro-aware)
- [ ] Implement desktop components installation
- [ ] Implement TUI tools installation
- [ ] Implement Wayland utilities installation
- [ ] Implement session file creation for GDM
- [ ] Add shellcheck validation to test.sh
- [ ] Test dry-run mode
- [ ] Test on Ubuntu 24.04
- [ ] Test on Arch Linux
- [ ] Test idempotency (re-run installation)
- [ ] Verify GDM session selection
- [ ] Document network management choice in README
- [ ] Update main README.md with Hyprland package info

---

**End of Design Document**
