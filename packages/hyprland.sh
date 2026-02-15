#!/usr/bin/env bash
set -euo pipefail

# Hyprland Desktop Environment Package
# Installs a complete Hyprland-based desktop with Wayland, TUI tools, and utilities
# Inspired by Omarchy's component choices

source "$(dirname "${BASH_SOURCE[0]}")/../lib/os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

install_network_tools() {
    log_info "Installing network management tools..."

    # NetworkManager (default, GUI-friendly)
    install_package_with_mapping "network-manager,arch:networkmanager"

    # NetworkManager system tray applet
    # Note: On Debian/Ubuntu, network-manager-gnome provides nm-applet
    # Despite the name, it works on non-GNOME systems (uses GTK, not GNOME desktop)
    install_package_with_mapping "network-manager-applet,arch:network-manager-applet,debian:network-manager-gnome"

    # iwd (for Impala WiFi TUI)
    install_package "iwd"

    log_info "Both NetworkManager and iwd installed"
    log_info "Choose which to enable in your config/dotfiles:"
    log_info "  systemctl enable NetworkManager  # OR"
    log_info "  systemctl enable iwd"
}

install_hyprland_dependencies() {
    log_info "Installing Hyprland dependencies..."

    # Wayland infrastructure
    install_package_with_mapping "wayland,arch:wayland,debian:libwayland-client0"
    install_package "wayland-protocols"
    install_package "xdg-desktop-portal"

    # Portal backend (try Hyprland-specific, fallback to GTK)
    if ! install_package "xdg-desktop-portal-hyprland" 2>/dev/null; then
        log_info "Falling back to xdg-desktop-portal-gtk"
        install_package "xdg-desktop-portal-gtk"
    fi

    # Audio (PipeWire)
    install_package "pipewire"
    install_package "wireplumber"
    install_package_with_mapping "pipewire-pulse,arch:pipewire-pulse,debian:pipewire-pulse"

    # PipeWire development headers (needed for building TUI tools like wiremix)
    install_package_with_mapping "pipewire-dev,arch:pipewire,debian:libpipewire-0.3-dev"

    # Bluetooth
    install_package "bluez"
    install_package_with_mapping "bluez-utils,arch:bluez-utils,debian:bluez-tools"

    # Network
    install_network_tools

    # Display Manager
    if ! command -v gdm &> /dev/null && ! command -v gdm3 &> /dev/null; then
        log_info "Installing GDM display manager..."
        install_package_with_mapping "gdm,arch:gdm,debian:gdm3"
    else
        log_info "GDM already installed"
    fi

    # Graphics
    # Mesa OpenGL drivers (package names differ by distro)
    install_package_with_mapping "mesa,arch:mesa,debian:libgl1-mesa-dri"
    install_package_with_mapping "vulkan-loader,arch:vulkan-icd-loader,debian:libvulkan1"

    log_info "Hyprland dependencies installed"
}

install_hyprland_core() {
    log_info "Installing Hyprland core components..."

    if is_arch; then
        install_package "hyprland"
        install_package "hyprlock"
        install_package "hypridle"
        log_info "Hyprland core installed"
    elif is_debian_like; then
        log_warn "Hyprland is not available in Ubuntu/Debian official repositories"
        log_warn "The community PPA is no longer maintained"
        log_info ""
        log_info "To install Hyprland on Ubuntu 24.04, you have these options:"
        log_info "  1. Build from source (recommended):"
        log_info "     https://wiki.hypr.land/Getting-Started/Installation/"
        log_info ""
        log_info "  2. Use the installation script:"
        log_info "     curl -fsSL https://hyprland.org/install | bash"
        log_info ""
        log_info "  3. Manual build instructions:"
        log_info "     git clone --recursive https://github.com/hyprwm/Hyprland"
        log_info "     cd Hyprland && make all && sudo make install"
        log_info ""
        log_warn "Skipping Hyprland core installation - please install manually"
        log_info "Other Hyprland components will still be installed"
        return 0
    else
        log_error "Unsupported distribution for Hyprland installation"
        return 1
    fi
}

install_desktop_components() {
    log_info "Installing desktop components..."

    install_package "waybar"
    install_package_with_mapping "mako,arch:mako,debian:mako-notifier"

    # SwayOSD (on-screen display for volume/brightness)
    # Only available on Arch - not in Ubuntu repos
    if is_arch; then
        install_package "swayosd"
    else
        log_info "SwayOSD not available on this distribution (Arch only)"
        log_info "For OSD functionality, configure volume/brightness in Hyprland config"
    fi

    install_package "nautilus"

    log_info "Desktop components installed"
}

install_tui_tools() {
    log_info "Installing TUI system management tools..."

    # These will use custom installers from installers/ directory
    install_package "wiremix"
    install_package "bluetui"
    install_package "impala"

    log_info "TUI tools installed"
}

install_wayland_utilities() {
    log_info "Installing Wayland utilities..."

    # Screenshot tools
    install_package "grim"
    install_package "slurp"

    # Clipboard utilities
    install_package "wl-clipboard"
    install_package "cliphist"

    # System tray applets
    install_package_with_mapping "network-manager-applet,arch:network-manager-applet,debian:network-manager-gnome"
    install_package "blueman"

    # Authentication agent
    install_package_with_mapping "polkit-gnome,arch:polkit-gnome,debian:policykit-1-gnome"

    log_info "Wayland utilities installed"
}

setup_session_file() {
    local session_dir="/usr/share/wayland-sessions"
    local session_file="${session_dir}/hyprland.desktop"
    local dry_run="${DRY_RUN:-false}"

    # Check if GDM is installed
    if ! command -v gdm &> /dev/null && ! command -v gdm3 &> /dev/null; then
        log_warn "GDM not found, skipping session file creation"
        log_warn "Start Hyprland manually or install a display manager"
        return 0
    fi

    # Check if session file already exists
    if [[ -f "$session_file" ]]; then
        log_info "Hyprland session file already exists"
        return 0
    fi

    if [[ "$dry_run" == true ]]; then
        log_info "Would create Hyprland session file at $session_file (dry-run)"
        return 0
    fi

    # Create session directory if needed
    if [[ ! -d "$session_dir" ]]; then
        sudo mkdir -p "$session_dir"
    fi

    # Create session file
    log_info "Creating Hyprland session file..."
    sudo tee "$session_file" > /dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF

    sudo chmod 644 "$session_file"
    log_info "Hyprland will appear in GDM session list"
}

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

    echo ""
    echo "=========================================="
    log_info "✓ Hyprland desktop environment installation complete!"
    echo "=========================================="
    log_info ""
    log_info "Next steps:"
    log_info "  1. Log out of your current session"
    log_info "  2. At GDM login, click the gear icon and select 'Hyprland'"
    log_info "  3. Configure Hyprland via your dotfiles (~/.config/hypr/)"
    log_info ""
    log_info "Note: Hyprland core must be installed manually on Ubuntu (see instructions above)"
    log_info "Network management: Choose NetworkManager OR iwd (see logs above)"
    echo "=========================================="
    log_info ""
}
