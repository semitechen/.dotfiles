#!/usr/bin/env bash
#
# kickstart.sh: Complete Arch Linux system bootstrap for Framework 13 Pro
#
# Assumes:
# 1. Fresh Arch Linux installation (e.g. minimal archinstall)
# 2. git and paru installed
# 3. ~/.dotfiles cloned on branch 'arch' and decrypted with git-crypt unlock
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="${DOTFILES_DIR}/paru/.config/paru/packages.txt"

# ANSI Colors
BOLD="\033[1m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${BOLD}${BLUE}=====================================================${RESET}"
echo -e "${BOLD}${BLUE}  Framework 13 Pro Arch Linux Bootstrap (kickstart)  ${RESET}"
echo -e "${BOLD}${BLUE}=====================================================${RESET}\n"

# 1. Pre-flight checks
if [ "$(uname -s)" != "Linux" ]; then
    echo -e "${RED}[Error] This script is designed for Arch Linux.${RESET}" >&2
    exit 1
fi

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[Error] Do not run kickstart.sh as root/sudo! Run as your regular user.${RESET}" >&2
    exit 1
fi

# Authenticate sudo upfront and keep session alive during unattended package installs
echo -e "${BLUE}::${RESET} ${BOLD}Authenticating sudo for system setup...${RESET}"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null || true' EXIT

if ! command -v paru >/dev/null 2>&1; then
    echo -e "${YELLOW}[Warning] 'paru' was not found in PATH.${RESET}"
    echo -e "Ensuring base-devel and git are installed before building paru..."
    sudo pacman -S --needed --noconfirm base-devel git
    echo -e "Attempting to bootstrap paru-bin from AUR..."
    BOOTSTRAP_DIR="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru-bin.git "$BOOTSTRAP_DIR"
    (cd "$BOOTSTRAP_DIR" && makepkg -si --noconfirm)
    rm -rf "$BOOTSTRAP_DIR"
fi

if [ ! -f "$PACKAGE_FILE" ]; then
    echo -e "${RED}[Error] Package list not found at: $PACKAGE_FILE${RESET}" >&2
    exit 1
fi

# Check if git-crypt repository is unlocked
if head -c 10 "$PACKAGE_FILE" 2>/dev/null | grep -q "GITCRYPT"; then
    echo -e "${RED}[Error] Dotfiles repository is still encrypted!${RESET}" >&2
    echo -e "Please unlock git-crypt before running kickstart:" >&2
    echo -e "  git-crypt unlock /path/to/dotfiles.key\n" >&2
    exit 1
fi

# 2. Parse and install all packages from packages.txt
echo -e "${BLUE}::${RESET} ${BOLD}Reading packages from paru/.config/paru/packages.txt...${RESET}"
packages=()
while IFS= read -r line || [ -n "$line" ]; do
    # Strip leading whitespace
    trimmed="${line#"${line%%[![:space:]]*}"}"
    # Skip comments and empty lines
    [[ -z "$trimmed" || "$trimmed" =~ ^# ]] && continue
    # Extract package name (first token)
    pkg_name=$(echo "$trimmed" | awk '{print $1}')
    if [ -n "$pkg_name" ]; then
        packages+=("$pkg_name")
    fi
done < "$PACKAGE_FILE"

echo -e "${GREEN}✓${RESET} Identified ${BOLD}${#packages[@]}${RESET} packages to install."

echo -e "\n${BLUE}::${RESET} ${BOLD}Installing packages via paru (unattended with --needed)...${RESET}"
set +e
paru -S --needed --noconfirm "${packages[@]}"
paru_exit=$?
set -e

if [ $paru_exit -ne 0 ]; then
    echo -e "\n${YELLOW}[Notice] Batch installation encountered an issue. Retrying packages individually...${RESET}"
    failed_pkgs=()
    for pkg in "${packages[@]}"; do
        set +e
        paru -S --needed --noconfirm "$pkg"
        pkg_exit=$?
        set -e
        if [ $pkg_exit -ne 0 ]; then
            failed_pkgs+=("$pkg")
        fi
    done

    if [ ${#failed_pkgs[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}[Notice] The following package(s) require manual intervention:${RESET}"
        for f in "${failed_pkgs[@]}"; do
            echo -e "  - ${BOLD}$f${RESET}"
            if [ "$f" = "davinci-resolve" ]; then
                echo -e "    ${YELLOW}↳ Note: DaVinci Resolve requires manually downloading the Linux .zip installer from blackmagicdesign.com/support/ into your build cache before installing.${RESET}"
            fi
        done
        echo -e "You can complete their installation later with: paru -S <package>\n"
    fi
else
    echo -e "${GREEN}✓ All packages installed successfully.${RESET}\n"
fi

# 3. Purge unneeded default packages, legacy drivers, and orphans
echo -e "${BLUE}::${RESET} ${BOLD}Auditing and removing unneeded default packages...${RESET}"
BLOAT_PACKAGES=(
    nano                  # Replaced by neovim
    vi                    # Replaced by neovim
    dmenu                 # Replaced by rofi
    xterm                 # Replaced by kitty
    xf86-video-intel      # Harmful on Meteor Lake Arc GPU (modesetting driver is superior)
    xf86-video-vesa       # Unneeded legacy fallback driver
    dhcpcd                # Conflicts with NetworkManager
    netctl                # Legacy network configuration
    thunar                # Yazi is exclusive file manager
    nautilus              # Yazi is exclusive file manager
    dolphin               # Yazi is exclusive file manager
    pcmanfm               # Yazi is exclusive file manager
)

to_remove=()
for pkg in "${BLOAT_PACKAGES[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
        to_remove+=("$pkg")
    fi
done

if [ ${#to_remove[@]} -gt 0 ]; then
    echo -e "Removing unneeded packages: ${BOLD}${to_remove[*]}${RESET}..."
    sudo pacman -Rns --noconfirm "${to_remove[@]}" 2>/dev/null || true
    echo -e "${GREEN}✓ Removed unneeded packages.${RESET}\n"
else
    echo -e "${GREEN}✓ No unneeded packages found.${RESET}\n"
fi

# Clean up any leftover orphaned packages (dependencies no longer required)
orphans=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$orphans" ]; then
    echo -e "Cleaning orphaned dependencies..."
    sudo pacman -Rns --noconfirm $orphans 2>/dev/null || true
    echo -e "${GREEN}✓ Cleaned orphan packages.${RESET}\n"
fi

# 4. Create required user directories
echo -e "${BLUE}::${RESET} ${BOLD}Setting up user directories...${RESET}"
mkdir -p \
    "$HOME/.config" \
    "$HOME/.local/bin" \
    "$HOME/.local/share" \
    "$HOME/.local/src" \
    "$HOME/.ssh" \
    "$HOME/archive" \
    "$HOME/hardwire" \
    "$HOME/media" \
    "$HOME/music/artists" \
    "$HOME/music/playlists" \
    "$HOME/notes" \
    "$HOME/projects" \
    "$HOME/studia" \
    "$HOME/workspaces" \
    "$HOME/Downloads"
chmod 700 "$HOME/.ssh" 2>/dev/null || true

# 5. Stow dotfiles packages
echo -e "${BLUE}::${RESET} ${BOLD}Stowing dotfiles configurations...${RESET}"
cd "$DOTFILES_DIR"

STOW_PACKAGES=(
    fish
    nvim
    tmux
    git
    aerc
    beets
    spotatui
    iamb
    ssh
    vpn
    wallpapers
    yazi
    gemini
    kitty
    gh
    darktable
    xinit
    paru
    rofi
    systemd
    fastfetch
    handlr
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$pkg" ]; then
        stow --restow -v -d "$DOTFILES_DIR" -t "$HOME" "$pkg" 2>&1 | sed 's/^/  /'
    fi
done
echo -e "${GREEN}✓ Dotfiles stowed.${RESET}\n"

# 6. Ensure correct permissions for scripts and security keys
chmod +x "$DOTFILES_DIR/xinit/.xinitrc" "$HOME/.xinitrc" 2>/dev/null || true
chmod +x "$DOTFILES_DIR/paru/.local/bin/"* "$HOME/.local/bin/"* 2>/dev/null || true
chmod +x "$DOTFILES_DIR/yazi/.local/bin/"* "$HOME/.local/bin/"* 2>/dev/null || true
chmod +x "$DOTFILES_DIR/handlr/.local/bin/"* "$HOME/.local/bin/"* 2>/dev/null || true
chmod +x "$DOTFILES_DIR/tmux/.config/tmux/scripts/sessionizer.sh" 2>/dev/null || true
chmod +x "$DOTFILES_DIR/aerc/.config/aerc/filters/"* 2>/dev/null || true
chmod +x "$DOTFILES_DIR/beets/.config/beets/essentia_extractor" 2>/dev/null || true
chmod 600 "$DOTFILES_DIR/ssh/.ssh/config" "$HOME/.ssh/config" 2>/dev/null || true
chmod 600 "$DOTFILES_DIR/vpn/.vpn"/*/* 2>/dev/null || true

# 7. Apply system-wide X11 input configurations (Polish dual-Alt keyboard & Touchpad)
if [ -d "$DOTFILES_DIR/xorg" ]; then
    echo -e "${BLUE}::${RESET} ${BOLD}Installing system-wide X11 input configurations (keyboard & touchpad)...${RESET}"
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo cp -f "$DOTFILES_DIR/xorg/"*.conf /etc/X11/xorg.conf.d/
    echo -e "${GREEN}✓ Installed X11 configurations in /etc/X11/xorg.conf.d/:${RESET}"
    for f in "$DOTFILES_DIR/xorg/"*.conf; do
        [ -f "$f" ] && echo -e "  ${GREEN}→${RESET} /etc/X11/xorg.conf.d/$(basename "$f")"
    done
    echo ""
fi

# 8. Configure & Enable Systemd Services
echo -e "${BLUE}::${RESET} ${BOLD}Configuring system services for Framework 13 Pro...${RESET}"

# NetworkManager
if systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
    sudo systemctl enable --now NetworkManager
    echo -e "${GREEN}✓ Enabled NetworkManager.${RESET}"
fi

# Power Profiles Daemon (Framework recommended for Intel Core Ultra)
if systemctl list-unit-files power-profiles-daemon.service >/dev/null 2>&1; then
    sudo systemctl enable --now power-profiles-daemon
    echo -e "${GREEN}✓ Enabled power-profiles-daemon.${RESET}"
fi

# SSD TRIM timer for Lexar NM790 NVMe
if systemctl list-unit-files fstrim.timer >/dev/null 2>&1; then
    sudo systemctl enable --now fstrim.timer
    echo -e "${GREEN}✓ Enabled fstrim.timer for Lexar NM790 SSD.${RESET}"
fi

# Automatic systemd-boot EFI bootloader updates
if systemctl list-unit-files systemd-boot-update.service >/dev/null 2>&1; then
    sudo systemctl enable systemd-boot-update.service
    echo -e "${GREEN}✓ Enabled systemd-boot-update.service for automatic bootloader updates.${RESET}"
fi

# Configure zram-generator (compressed in-RAM swap, zero SSD wear for 32GB RAM)
if [ ! -f /etc/systemd/zram-generator.conf ]; then
    echo -e "${BLUE}::${RESET} ${BOLD}Configuring zram compressed swap device...${RESET}"
    sudo tee /etc/systemd/zram-generator.conf >/dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0 2>/dev/null || true
    echo -e "${GREEN}✓ Configured 16GB zstd compressed zram swap device.${RESET}"
fi

# Set optimal kernel swappiness for zram
if [ ! -f /etc/sysctl.d/99-swappiness.conf ]; then
    sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null << 'EOF'
vm.swappiness = 60
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF
    sudo sysctl --system >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Applied optimal sysctl swappiness for zram.${RESET}"
fi

# Btrfs monthly scrub timer to verify checksums and integrity on Lexar SSD
if systemctl list-unit-files btrfs-scrub@.timer >/dev/null 2>&1; then
    sudo systemctl enable --now btrfs-scrub@-.timer 2>/dev/null || true
    echo -e "${GREEN}✓ Enabled periodic btrfs scrub timer for filesystem integrity.${RESET}"
fi

# User-level PipeWire audio services
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
echo -e "${GREEN}✓ Enabled PipeWire and WirePlumber audio stack.${RESET}"

# User-level automatic Downloads cleanup (> 30 days) via systemd-tmpfiles
systemctl --user enable --now systemd-tmpfiles-clean.timer 2>/dev/null || true
echo -e "${GREEN}✓ Enabled systemd-tmpfiles-clean.timer for automatic 30-day Downloads cleanup.${RESET}"

# User-level XDG Desktop Portal for Yazi file chooser
systemctl --user enable --now xdg-desktop-portal 2>/dev/null || true
echo -e "${GREEN}✓ Enabled xdg-desktop-portal service for Yazi file chooser.${RESET}"

# Register default application associations via handlr & xdg-mime
if command -v handlr >/dev/null 2>&1; then
    handlr set inode/directory yazi.desktop
    handlr set x-scheme-handler/http helium-browser.desktop
    handlr set x-scheme-handler/https helium-browser.desktop
    handlr set x-scheme-handler/terminal kitty.desktop
    echo -e "${GREEN}✓ Registered default associations via handlr.${RESET}"
elif command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default yazi.desktop inode/directory
    echo -e "${GREEN}✓ Registered Yazi as default handler for inode/directory.${RESET}"
fi

# Shadow xdg-open system-wide with handlr (/usr/local/bin/xdg-open)
if command -v handlr >/dev/null 2>&1; then
    sudo tee /usr/local/bin/xdg-open >/dev/null << 'EOF'
#!/bin/sh
exec handlr open "$@"
EOF
    sudo chmod +x /usr/local/bin/xdg-open
    echo -e "${GREEN}✓ Shadowed xdg-open with handlr system-wide (/usr/local/bin/xdg-open).${RESET}\n"
else
    echo ""
fi

# 9. Set Default User Shell to Fish
if command -v fish >/dev/null 2>&1; then
    FISH_BIN="$(command -v fish)"
    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
    if [ "$CURRENT_SHELL" != "$FISH_BIN" ]; then
        echo -e "${BLUE}::${RESET} ${BOLD}Changing default shell to fish ($FISH_BIN)...${RESET}"
        if ! grep -q "$FISH_BIN" /etc/shells; then
            echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
        fi
        sudo chsh -s "$FISH_BIN" "$USER"
        echo -e "${GREEN}✓ Default shell changed to fish.${RESET}\n"
    fi
fi

# 10. Clone, build, and install dwm
echo -e "${BLUE}::${RESET} ${BOLD}Installing suckless dwm window manager...${RESET}"
DWM_DIR="$HOME/.local/src/dwm"
if [ ! -d "$DWM_DIR" ]; then
    echo "Cloning dwm repository..."
    git clone https://github.com/semitechen/dwm.git "$DWM_DIR"
else
    echo "Updating dwm repository..."
    (cd "$DWM_DIR" && git pull --ff-only 2>/dev/null || true)
fi

echo "Compiling and installing dwm..."
(cd "$DWM_DIR" && sudo make clean install)
echo -e "${GREEN}✓ dwm installed to /usr/local/bin/dwm.${RESET}\n"

# 11. Next Steps Summary
echo -e "${BOLD}${GREEN}=====================================================${RESET}"
echo -e "${BOLD}${GREEN}  Kickstart Complete! System is Fully Configured.    ${RESET}"
echo -e "${BOLD}${GREEN}=====================================================${RESET}\n"

echo -e "You can now launch your minimal dwm desktop with:\n"
echo -e "     ${BOLD}startx${RESET}\n"
