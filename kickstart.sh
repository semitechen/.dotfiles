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

if ! command -v paru >/dev/null 2>&1; then
    echo -e "${YELLOW}[Warning] 'paru' was not found in PATH.${RESET}"
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
paru -S --needed --noconfirm "${packages[@]}"
echo -e "${GREEN}✓ All packages installed successfully.${RESET}\n"

# 3. Create required user directories
echo -e "${BLUE}::${RESET} ${BOLD}Setting up user directories...${RESET}"
mkdir -p \
    "$HOME/.config" \
    "$HOME/.local/bin" \
    "$HOME/.local/share" \
    "$HOME/.local/src" \
    "$HOME/Music/dj/music" \
    "$HOME/Music/dj/playlists" \
    "$HOME/Pictures/Darktable" \
    "$HOME/Downloads" \
    "$HOME/Documents"

# 4. Stow dotfiles packages
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
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$pkg" ]; then
        stow --restow -v -d "$DOTFILES_DIR" -t "$HOME" "$pkg" 2>&1 | sed 's/^/  /'
    fi
done
echo -e "${GREEN}✓ Dotfiles stowed.${RESET}\n"

# 5. Ensure scripts are executable
chmod +x "$DOTFILES_DIR/xinit/.xinitrc" "$HOME/.xinitrc" 2>/dev/null || true
chmod +x "$DOTFILES_DIR/paru/.local/bin/"* "$HOME/.local/bin/"* 2>/dev/null || true

# 6. Apply system-wide X11 keyboard configuration (Polish dual-Alt)
if [ -f "$DOTFILES_DIR/xorg/00-keyboard.conf" ]; then
    echo -e "${BLUE}::${RESET} ${BOLD}Installing system-wide Polish dual-Alt XKB configuration...${RESET}"
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo cp -f "$DOTFILES_DIR/xorg/00-keyboard.conf" /etc/X11/xorg.conf.d/00-keyboard.conf
    echo -e "${GREEN}✓ Installed /etc/X11/xorg.conf.d/00-keyboard.conf.${RESET}\n"
fi

# 7. Configure & Enable Systemd Services
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

# User-level PipeWire audio services
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
echo -e "${GREEN}✓ Enabled PipeWire and WirePlumber audio stack.${RESET}\n"

# 8. Set Default User Shell to Fish
if command -v fish >/dev/null 2>&1; then
    FISH_BIN="$(which fish)"
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

# 9. Next Steps Summary
echo -e "${BOLD}${GREEN}=====================================================${RESET}"
echo -e "${BOLD}${GREEN}  Kickstart Complete! System is Configured.          ${RESET}"
echo -e "${BOLD}${GREEN}=====================================================${RESET}\n"

echo -e "Next steps to launch your minimal dwm desktop:\n"
echo -e "  1. Clone and compile your minimal dwm repository:"
echo -e "     ${BOLD}git clone <your-dwm-repo> ~/.local/src/dwm${RESET}"
echo -e "     ${BOLD}cd ~/.local/src/dwm && sudo make clean install${RESET}\n"
echo -e "  2. Start X11 session:"
echo -e "     ${BOLD}startx${RESET}\n"
