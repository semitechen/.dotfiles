# macOS to Arch Linux Migration Journal & Checklist

This document tracks all system differences, required configuration tweaks, and setup steps when transitioning from macOS (MacBook) to an Arch Linux laptop (Framework 13 Pro).

---

## 1. System Differences & Compatibility Tracker

| Category | macOS (Previous) | Arch Linux (Target) | Status on `arch` Branch |
| :--- | :--- | :--- | :--- |
| **Window Manager** | macOS WindowServer | `dwm` (X11) | ✅ **Handled**: Managed in a dedicated separate repository with an ultra-minimal setup (fullscreen apps, no borders, no status bar). |
| **Polish Diacritics (Dual-Alt)** | `kitty.conf` maps `alt+...` via `send_text` | X11 XKB `lv3:alt_switch` | ✅ **Handled**: Configured `setxkbmap -layout pl -option lv3:alt_switch` in `xinit/.xinitrc` and persistent `xorg/00-keyboard.conf`. Both Left and Right Alt act as AltGr system-wide (Framework 13 PC layout). Stripped macOS `send_text` overrides from `kitty.conf`. |
| **System Openers** | `/usr/bin/open` | `handlr` (`xdg-open` shadow) | ✅ **Handled**: Completely replaced `xdg-open` and `xdg-mime` with `handlr` (`handlr-regex`). Shadowed via `~/.local/bin/xdg-open`, `~/.local/bin/xdg-mime`, and `/usr/local/bin/xdg-open`. Configured Rofi selector and YouTube/mpv regex handling in `handlr.toml`. |
| **URL Opening in Terminal** | `Shift + Click` / `Ctrl + Shift + e` (Hints) | `Shift + Click` / `Ctrl + Shift + e` (Hints) | ✅ **Handled**: Kitty built-in URL handling bypasses terminal app mouse grabs (`aerc`, `nvim`). |
| **Clipboard** | `pbcopy` / `pbpaste` | `xclip` (X11) | ✅ **Handled**: Neovim uses `"+y` / `"+p` with `xclip`. No macOS clipboard tool invocations remain in dotfiles. |
| **Terminal Modifiers** | `cmd+t`, `cmd+w`, `cmd+n` in `kitty.conf` | dwm window management / tmux sessions | ✅ **Handled**: Stripped `cmd+` mappings from `kitty.conf`. Terminal splits and windows managed via `tmux` and `dwm`. |
| **macOS Options** | `macos_option_as_alt yes` | Not applicable (handled by XKB) | ✅ **Handled**: Removed `macos_option_as_alt` from `kitty.conf`. |
| **Launcher** | `raycast/` (macOS-only) | `rofi` (X11 / dwm) | ✅ **Handled**: Replaced Raycast with Rofi styled in Tokyo Night (`rofi/`). Deleted `raycast/` on `arch` branch. |
| **Shell Paths** | `fish_variables` has `/opt/homebrew` | Standard `/usr/bin`, `~/.local/bin`, `~/.cargo/bin` | ✅ **Handled**: Reset `fish_user_paths` to `/home/kacperjelonek/.local/bin` and `/home/kacperjelonek/.cargo/bin`. Updated `config.fish` and `tmux.conf`. |
| **Paths in Configs & DBs** | `/Users/kacperjelonek` | `/home/kacperjelonek` | ✅ **Handled**: Updated `spotatui/config.yml`, `darktable/darktablerc`. Removed Colima include in `ssh/config`. Untracked dynamic Darktable photo library database (`library.db`) in `.gitignore`. |
| **Darktable Secret Backend** | `apple_keychain` | `auto` (libsecret) | ✅ **Handled**: Changed `pwstorage_backend=auto` in `darktablerc`. |
| **Tmux Plugins** | TPM manual bootstrap | Auto-bootstrapping script in `tmux.conf` | ✅ **Handled**: Auto-clones and installs plugins on launch. |
| **Tmux Sessionizer** | `fzf` + `zoxide` popup | `fzf` + `zoxide` popup | ✅ **Handled**: Portable script at `tmux/scripts/sessionizer.sh`. |
| **Package Management** | Homebrew (`brew`) | `paru` (AUR Helper) with mandatory package reasons | ✅ **Handled**: Custom `paru` wrapper enforces non-empty comments on package install, logging to `packages.txt`. Fish functions, PATH wrappers, and bracketed paste handlers automatically translate `pacman` and `yay` (including `sudo`) to `paru`. |
| **Gemini / Antigravity** | `settings.json` + `config/` | `settings.json` + `config/` | ✅ **Handled**: Zero local paths in git; symlinked via `stow gemini`. |

---

## 2. Arch Linux Package Installation List

When setting up the new Arch laptop (Framework 13 Pro), install these core packages:

```bash
# Core CLI Tools, Shell, & Multiplexer
sudo pacman -S git git-crypt stow fish tmux neovim zoxide fzf ripgrep fd yazi

# Terminal & GUI Tools
sudo pacman -S kitty github-cli darktable

# Framework 13 Hardware Drivers & Firmware (Intel Core Ultra 5 / Meteor Lake)
sudo pacman -S intel-ucode linux-firmware sof-firmware alsa-ucm-conf mesa vulkan-intel intel-media-driver power-profiles-daemon fwupd

# Audio & PipeWire Stack
sudo pacman -S pipewire wireplumber pipewire-pulse pipewire-alsa aerc beets w3m openvpn alsa-utils

# X11, Display Scaling, & Utilities
sudo pacman -S base-devel xorg-server xorg-xinit xorg-setxkbmap xorg-xrandr xclip xorg-xrdb picom rofi dmenu feh brightnessctl

# Node & Python (Required for Gemini MCP servers & custom skills)
sudo pacman -S nodejs npm python python-pip

# Fonts (Nerd Fonts required for icons in tmux, kitty, & yazi)
sudo pacman -S ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
```

---

## 3. Fresh Arch Setup Recipe

1. **Clone Dotfiles**:
   ```bash
   git clone <repo_url> ~/.dotfiles
   cd ~/.dotfiles
   git checkout arch
   ```

2. **Unlock Secrets**:
   ```bash
   git-crypt unlock /path/to/exported-dotfiles.key
   ```

3. **Run Automated System Kickstart**:
   ```bash
   ./kickstart.sh
   ```
   *Installs all 64 packages from `packages.txt` via paru, stows all configurations, applies system Polish dual-Alt layout, enables systemd services (NetworkManager, power-profiles-daemon, fstrim), configures PipeWire audio, and sets fish as default shell.*

4. **Install dwm**:
   - Clone and compile your minimal dwm build from its dedicated repository:
     ```bash
     git clone <your-dwm-repo> ~/.local/src/dwm
     cd ~/.local/src/dwm && sudo make clean install
     ```

6. **Initialize Shell & Plugins**:
   - **Fish**: Launch `fish` and let `zoxide` initialize.
   - **Tmux**: Launch `tmux` (TPM will automatically install plugins on first launch).
   - **Neovim**: Open `nvim` (Lazy.nvim will automatically sync all plugins).
   - **Antigravity CLI**: Install `agy` Linux binary and run `agy` once to complete authentication.

7. **Start X11 & dwm**:
   ```bash
   startx
   ```

---

## 4. Post-Migration Notes & Tweaks Log

- **2026-10-19**:
  - Fully replaced `xdg-open` and `xdg-mime` with `handlr` (`handlr-regex`):
    - Added `handlr-regex` to `paru/.config/paru/packages.txt`.
    - Created `handlr` stow package with `~/.config/handlr/handlr.toml` enabling Rofi menu selector (`rofi -dmenu -i -p 'Open with:'`) when multiple handlers exist, and regex handler routing YouTube URLs directly to `mpv`.
    - Created executable wrappers `~/.local/bin/xdg-open` and `~/.local/bin/xdg-mime` (shadowing `xdg-utils` commands via user PATH precedence) mapping `xdg-open "$@"` to `handlr open "$@"` and translating `xdg-mime` subcommands (`default`, `query`) to `handlr set` and `handlr get`.
    - Automated system-wide shadow wrapper `/usr/local/bin/xdg-open` and default file/protocol association registration (`inode/directory` -> `yazi.desktop`, `http[s]` -> `helium-browser.desktop`) in `kickstart.sh`.
- **2026-10-18**:
  - Configured `dwm` with borderless (`borderpx = 0`), no bar (`showbar = 0`), monocle default layout, and dedicated app tag navigation shortcuts (`Super+d` for tmux, `Super+a` for aerc, `Super+s` for spotatui, `Super+z` for iamb, `Super+x` for helium, `Super+q` for kicad, `Super+Space` for rofi, `Super+Enter` for kitty). Added `Super+e` shortcut to launch Yazi and added floating window rule for `file_chooser`.
  - Implemented RAM-optimized TUI startup: all TUI apps launch under a single `kitty --single-instance` master daemon, sharing GPU sprite cache, OpenGL contexts, and engine to cut RAM from ~400MB to ~80MB total. Windows are routed to tags using `--class` matching.
  - Implemented automated 30-day cleanup of `~/Downloads`: configured `systemd/.config/user-tmpfiles.d/downloads.conf` with `d %h/Downloads 0755 - - 30d -` and enabled `systemd-tmpfiles-clean.timer` in user systemd. Added helper function `clean_downloads` in fish.
  - Configured Yazi as the exclusive system-wide file explorer: registered as default `inode/directory` handler in `mimeapps.list` and `yazi.desktop`. Integrated `xdg-desktop-portal-termfilechooser` with `yazi-chooser` so all GUI apps (Helium, KiCad, FreeCAD) open floating Yazi dialogs for Open/Save file actions without any GUI file managers installed.
  - Added automated bloat & orphan purging in `kickstart.sh`: removes redundant default editors (`nano`, `vi`), superseded tools (`dmenu`, `xterm`), conflicting network daemons (`dhcpcd`, `netctl`), GUI file managers (`thunar`, `nautilus`, `dolphin`, `pcmanfm`), legacy buggy GPU drivers (`xf86-video-intel`, `xf86-video-vesa`), and orphaned packages.
  - Configured `fastfetch` as the interactive Fish greeting: displays official Arch Linux ASCII logo and hardware/OS specs styled in Tokyo Night color palette. Added `fastfetch` stow package and added to `packages.txt`.
  - Added support and optimizations for systemd-boot + Btrfs + LUKS: added `btrfs-progs` and `zram-generator` (16GB zstd compressed in-RAM swap to prevent NVMe SSD write wear on 32GB RAM Framework 13), configured sysctl swappiness, enabled `systemd-boot-update.service` for automatic bootloader updates, and enabled `btrfs-scrub` timer. Documented subvolume layout (`@`, `@home`, `@var_log`, `@snapshots`) and mount options.
- **2026-10-16**:
  - Untracked Darktable's dynamic photo library (`library.db`) in `.gitignore` to prevent git churn every time Darktable is used.
  - Decoupled `dwm` into a dedicated separate repository for an ultra-minimal setup (fullscreen apps, borderless, no status bar).
  - Streamlined `xinit/.xinitrc` to a minimal launcher without background status loops.
- **2026-10-12 (Migration to Arch branch completed)**:
  - Created dedicated `arch` branch with complete Linux & dwm configurations.
  - Stripped all `/Users/kacperjelonek` and `/opt/homebrew` references across configs (`tmux.conf`, `config.fish`, `fish_variables`, `aerc.conf`, `spotatui/config.yml`, `darktablerc`, `library.db`, `ssh/config`).
  - Switched Darktable password storage backend from `apple_keychain` to `auto` (`libsecret`).
  - Updated audio player in Darktable from `afplay` to `aplay`.
  - Migrated Darktable SQLite `film_rolls.folder` database paths to `/home/kacperjelonek`.
  - Removed macOS Colima SSH include from `ssh/config`.
  - Created `xinit/.xinitrc` with dual-Alt Polish layout (`lv3:alt_switch`), wallpaper restoration, compositor (`picom`), status loop, and dwm execution.
  - Created `dwm/config.h` configured with `MODKEY = Mod4Mask` (Super/Win key), Tokyo Night color scheme, Kitty terminal launcher, dmenu launcher, and hardware multimedia/brightness keybindings for Framework 13 Pro.
  - Created `dwm/install.sh` automated dwm compilation and installation script.
  - Created persistent `xorg/00-keyboard.conf` for `/etc/X11/xorg.conf.d/`.
  - Cleaned `kitty.conf`: stripped deprecated `resize_draw_strategy static`, removed `cmd+` keybindings, removed `macos_option_as_alt yes`, and removed macOS Polish diacritic text-injection workarounds (now natively handled by XKB).
- **2026-09-22**:
  - Target machine set to Framework 13 Pro (PC layout).
  - Window manager chosen as `dwm` on X11.
  - Resolved Polish diacritics strategy for Linux: use `lv3:alt_switch` in XKB so both Left and Right Alt produce Polish characters (`ą`, `ć`, `ę`, etc.) identically across all apps, matching macOS Option behavior.
  - Documented mandatory `MODKEY = Mod4Mask` setting in `dwm/config.h` to prevent dwm's default kill client shortcut (`Mod1+Shift+c`) from intercepting Polish `Ć`.
- **2026-08-20**:
  - Replaced submodules with manifest-driven plugin management (`lazy-lock.json` and TPM auto-install).
  - Added portable `sessionizer.sh` for instant project switching (`fzf` + `zoxide` on `prefix+N`).
  - Stripped local workspace paths from `settings.json` and gitignored `gemini/projects/`.
