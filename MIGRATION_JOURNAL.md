# macOS to Arch Linux Migration Journal & Checklist

This document tracks all system differences, required configuration tweaks, and setup steps when transitioning from macOS (MacBook) to an Arch Linux laptop (Framework 13 Pro).

---

## 1. System Differences & Compatibility Tracker

| Category | macOS (Previous) | Arch Linux (Target) | Status on `arch` Branch |
| :--- | :--- | :--- | :--- |
| **Window Manager** | macOS WindowServer | `dwm` (X11) | ✅ **Handled**: Managed in a dedicated separate repository with an ultra-minimal setup (fullscreen apps, no borders, no status bar). |
| **Polish Diacritics (Dual-Alt)** | `kitty.conf` maps `alt+...` via `send_text` | X11 XKB `lv3:alt_switch` | ✅ **Handled**: Configured `setxkbmap -layout pl -option lv3:alt_switch` in `xinit/.xinitrc` and persistent `xorg/00-keyboard.conf`. Both Left and Right Alt act as AltGr system-wide (Framework 13 PC layout). Stripped macOS `send_text` overrides from `kitty.conf`. |
| **Touchpad & Gestures** | macOS trackpad gestures & natural scrolling | X11 libinput (`30-touchpad.conf`) | ✅ **Handled**: Configured tap-to-click (`Tapping on`), tap-to-click mapping (`TappingButtonMap lrm` for 1-finger left, 2-finger right, 3-finger middle click), tap-and-drag (`TappingDrag true`), physical clickfinger (`ClickMethod clickfinger`), natural scrolling (`NaturalScrolling true`), two-finger scroll (`ScrollMethod twofinger`), palm rejection (`DisableWhileTyping true`), and standard button order `1 2 3 4 5 6 7` in `/etc/X11/xorg.conf.d/30-touchpad.conf`. Driver `xf86-input-libinput` managed in `packages.txt`. |
| **System Openers** | `/usr/bin/open` | `handlr` (`xdg-open` shadow) | ✅ **Handled**: Completely replaced `xdg-open` and `xdg-mime` with `handlr` (`handlr-regex`). Shadowed via `~/.local/bin/xdg-open`, `~/.local/bin/xdg-mime`, and `/usr/local/bin/xdg-open`. Configured Rofi selector and YouTube/mpv regex handling in `handlr.toml`. |
| **URL Opening in Terminal** | `Shift + Click` / `Ctrl + Shift + e` (Hints) | `Shift + Click` / `Ctrl + Shift + e` (Hints) | ✅ **Handled**: Kitty built-in URL handling bypasses terminal app mouse grabs (`aerc`, `nvim`). |
| **Clipboard** | `pbcopy` / `pbpaste` | `xclip` (X11) | ✅ **Handled**: Neovim uses `"+y` / `"+p` with `xclip`. No macOS clipboard tool invocations remain in dotfiles. |
| **Terminal Modifiers** | `cmd+t`, `cmd+w`, `cmd+n` in `kitty.conf` | dwm window management / tmux sessions | ✅ **Handled**: Stripped `cmd+` mappings from `kitty.conf`. Terminal splits and windows managed via `tmux` and `dwm`. |
| **macOS Options** | `macos_option_as_alt yes` | Not applicable (handled by XKB) | ✅ **Handled**: Removed `macos_option_as_alt` from `kitty.conf`. |
| **Launcher** | `raycast/` (macOS-only) | `rofi` (X11 / dwm) | ✅ **Handled**: Replaced Raycast with Rofi styled in Tokyo Night (`rofi/`). Deleted `raycast/` on `arch` branch. |
| **Shell Paths** | `fish_variables` has `/opt/homebrew` | Standard `/usr/bin`, `~/.local/bin`, `~/.cargo/bin` | ✅ **Handled**: Reset `fish_user_paths` to `/home/semitechen/.local/bin` and `/home/semitechen/.cargo/bin`. Updated `config.fish` and `tmux.conf`. |
| **Paths in Configs & DBs** | `/Users/kacperjelonek` | `/home/semitechen` | ✅ **Handled**: Updated `spotatui/config.yml`, `darktable/darktablerc`. Removed Colima include in `ssh/config`. Untracked dynamic Darktable photo library database (`library.db`) in `.gitignore`. |
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
sudo pacman -S base-devel xorg-server xf86-input-libinput xorg-xinit xorg-setxkbmap xorg-xrandr xclip xorg-xrdb picom rofi feh brightnessctl

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
     git clone https://github.com/semitechen/dwm.git ~/.dwm
     cd ~/.dwm && sudo make clean install
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

- **2026-10-21**:
  - Full keyboard continuity, CJK typography, app provisioning, and branch synchronization:
    - **CJK & Unicode Font Fallback**: Resolved Chinese/CJK characters displaying as tofu/squares by installing `wqy-microhei` outline font, adding `symbol_map` in `kitty.conf` covering CJK Unified Ideographs and punctuation (`U+4E00-U+9FFF`, `U+3400-U+4DBF`, `U+3000-U+303F`, `U+FF00-U+FFEF`), and tracking `wqy-microhei`, `noto-fonts-cjk`, and `noto-fonts-emoji` in `packages.txt`.
    - **Alt / Option & Polish Diacritic Continuity**:
      - Diagnosed and resolved broken `Alt+.` and `Alt+,` shortcuts across terminal, tmux, and GUI apps: previously `Option "XkbOptions" "lv3:alt_switch"` mapped `<LALT>` to `ISO_Level3_Shift`, converting Left Alt into a Level 3 modifier that outputted `greaterthanequal` (`≥`) on period and `lessthanequal` (`≤`) on comma while stripping `Mod1` (Alt/Meta).
      - Removed `lv3:alt_switch` from `xorg/00-keyboard.conf` and `xinit/.xinitrc`. Left Alt is a true `Alt_L` (`Mod1`), while Right Alt serves as standard `AltGr` (`ISO_Level3_Shift`).
      - In `xinit/.config/xkb/custom.xkb`, implemented XKB `RedirectKey` actions for comma `<AB08>` and period `<AB09>` so that Level 3 (Right Alt) redirects to `keycode` with `modifiers=Mod1` and `clearModifiers=LevelThree` (and Level 4 with `Shift+Mod1`). This converts Right Alt + `,` and Right Alt + `.` at the core X11 event dispatch level into true Alt+, and Alt+. events across all GUI (Helium, KiCad) and CLI applications without altering any of the 9 Polish diacritics (`ą, ć, ę, ł, ń, ó, ś, ź, ż`).
      - Fixed startup race condition in `xinit/.xinitrc` by executing `xkbcomp` synchronously before launching dwm and client applications.
      - Implemented multi-tier application fallbacks:
        * `kitty.conf`: Added explicit `alt+,`, `alt+.`, `alt+shift+,`, `alt+shift+.` bindings mapping to `\x1b,`, `\x1b.`, `\x1b<`, `\x1b>` alongside raw `≤` and `≥` mappings.
        * `fish/config.fish`: Added `\e.`, `\e,`, `≤`, and `≥` to `history-token-search-backward` and `history-token-search-forward`.
        * `aerc/binds.conf`: Added `≤` and `≥` fallback bindings to `:prev-tab` and `:next-tab` across `[messages]`, `[compose]`, `[compose::editor]`, and `[terminal]`.
        * `iamb/config.toml`: Added `<A-,>`, `<A-.>`, `≤`, and `≥` to `:tabp` and `:tabn` under `[macros.normal]`.
        * `nvim/lua/plugins/ui.lua`: Configured `<A-,>`, `<A-.>`, `≤`, and `≥` to cycle tabs via BufferLine.
    - **App Availability & Autostart Completeness**:
      - Created `/usr/local/bin/helium` alias to `/usr/bin/helium-browser` and automated it in `kickstart.sh` so `helium` executes directly.
      - Added missing Tag 6 KiCad hardware EDA autostart to `xinit/.xinitrc` alongside tmux, aerc, spotatui, iamb, and helium.
      - Confirmed 101 of 102 packages installed; documented manual upstream archive requirement for `davinci-resolve`.
    - **Repository & Stow Hygiene**:
      - Purged accidental stow symlinks and `.local` remnants from `fish/`.
      - Updated `.gitignore` to exclude `antigravity-cli` runtime logs, databases, and caches.
      - Added `.gitignore` in `~/.dwm` for build objects and binaries.
      - Restowed all 23 GNU Stow packages cleanly with zero conflicts.
      - Fully synchronized and pushed `main` and `arch` branches to GitHub.
  - Comprehensive bootstrap automation, packaging, and association hardening:
    - **Bootstrap `git-crypt` Pre-check**: Fixed fatal bootstrapping bug in `kickstart.sh` where fresh installs attempted `git-crypt unlock` without `git-crypt` being installed on the system, which would abort the script. Added upfront `pacman -S --needed --noconfirm git-crypt` check.
    - **Default File Associations**: Registered standard desktop associations across `yazi/.config/mimeapps.list` and `kickstart.sh` (`text/plain` -> `nvim.desktop`, `application/pdf` -> `helium-browser.desktop`, `image/png` / `image/jpeg` -> `feh.desktop`, `video/mp4` / `video/quicktime` -> `mpv.desktop`).
    - **Paru Wrapper Hardening**:
      - Added git-crypt lock protection in `paru/.local/bin/paru` to prevent plain text appends from corrupting encrypted `packages.txt`.
      - Expanded CLI option parser to skip arguments for `--overwrite`, `--assume-installed`, `--ignore`, and `--ignoregroup`.
      - Hoisted interactive prompt file descriptors (FDs 3 and 4) outside the per-package loop and explicitly closed them (`exec 3<&- 4>&-`) prior to delegating to real `paru`/`pacman` binary.
      - Escaped internal double quotes in comment inputs to ensure clean formatting in `packages.txt`.
    - **Shadowing & Mime Wrapper Robustness**:
      - Updated `kickstart.sh` to copy `handlr/.local/bin/xdg-open` directly to `/usr/local/bin/xdg-open` ensuring single-source-of-truth.
      - Updated `handlr/.local/bin/xdg-mime` `default` action to loop over all supplied MIME types so multi-argument calls set all targets cleanly.
    - **Tmux Sessionizer Filtering**: Excluded `.git`, `node_modules`, and `__pycache__` directories from `find` in `sessionizer.sh` to eliminate repository and cache clutter in the `fzf` session picker.
    - **Security & Privacy Permissions**: Added `0700` directory permission enforcement for `~/.vpn` and its subdirectories in `kickstart.sh`.
    - **Darktable Config Cleanup**: Updated export file directory pattern in `darktablerc` from legacy `/home/semitechen/Pictures/skany/...` to `/home/semitechen/media/$(FILE_NAME)` and updated collect history entry 5 to `/home/semitechen/workspaces/Darktable$`.
    - **Fail-safe Autostart Timeout in `.xinitrc`**: Replaced unbounded `while ! pgrep -x kitty` loop with a bounded 3-second timeout (`[ $count -lt 30 ]`) to prevent X11 freeze in case Kitty fails to launch.
    - **Pre-provisioning `stow` & Signal Handling in `kickstart.sh`**: Added `stow` to initial pacman base installation ensuring dotfiles can always be linked even on partial package installs, expanded sudo keep-alive cleanup trap to `INT TERM EXIT`, and added directory safety check before compiling dwm.
    - **GNU Stow Ignore Hygiene**: Added `__pycache__`, `.*\.pyc$`, and `.*\.stowbak$` to `.stow-local-ignore`.
- **2026-10-19**:
  - Migrated target system username from `kacperjelonek` to `semitechen` across all configurations:
    - Updated `kitty.conf` background image path to `/home/semitechen/.wallpapers/testbg.png`.
    - Updated `tmux.conf` PATH to `/home/semitechen/.local/bin:/home/semitechen/.cargo/bin:...`.
    - Updated `xdg-desktop-portal-termfilechooser/config` to `/home/semitechen/.local/bin/yazi-chooser`.
    - Updated `spotatui/config.yml` `local_music_path` to `/home/semitechen/music/artists`.
- **2026-10-20**:
  - Comprehensive pre-flight system and configuration bug audit:
    - Fixed YAML syntax violation in `beets/config.yaml`: quoted `default` and `singleton` path templates starting with `%the{...}` to comply with YAML directive specification.
    - Added missing runtime packages to `packages.txt`: `xorg-xsetroot` (for dwm mouse cursor setup), `xorg-xauth` (for SSH X11 forwarding to `pul` and `cadence`), `git-lfs` (required by gitconfig filter configuration), `adwaita-cursors` (for `Xcursor.theme: Adwaita` in `~/.Xresources`), `imagemagick` (for `magick`/`convert` in `aerc` image viewer), `python-discogs-client` & `python-spotipy` (for `beets` plugins), `playerctl` (MPRIS media controller for spotatui), `networkmanager` (network daemon & nmcli), `bluez` & `bluez-utils` (Bluetooth daemon & bluetoothctl), `pipewire-audio` (SPA Bluetooth codecs: AAC, LDAC, aptX), `udisks2` (unprivileged USB mounting), and `exfatprogs` (exFAT utilities for USB pendrive).
    - Updated `kickstart.sh`: automated system-wide shadowing of both `xdg-open` and `xdg-mime` via `handlr` into `/usr/local/bin`, added user to hardware access groups (`video` for brightnessctl, `uucp` for serial/FPGA/Pico, `input` for libinput), enabled `bluetooth.service`, added auto-detection/unlocking of `dotfiles.key`, and implemented automated pre-stow regular file conflict resolution (`*.stowbak`) to prevent bootstrap abortions.
    - Updated `tmux-powerline/config.sh`: switched `TMUX_POWERLINE_SEG_NOW_PLAYING_MUSIC_PLAYER` to `playerctl` to display track information natively from `spotatui` (or Helium / mpv) via MPRIS.
    - Updated `darktable/darktablerc`: migrated photo library collection history paths from `~/Pictures/Darktable` to `~/workspaces/Darktable` to match the new flat folder layout.
    - Updated `xinit/.xinitrc`: added `dunst &` to autostart the notification daemon on X11 login to prevent DBus notification timeouts.
    - Updated `dwm` repository (`semitechen/dwm`): configured `<X11/XF86keysym.h>` bindings for hardware multimedia and brightness keys on Framework 13 Pro (Volume Up/Down/Mute via `wpctl`, Screen Brightness Up/Down via `brightnessctl`, and Play/Next/Prev via `playerctl`), committed and pushed to GitHub.
  - Reorganized personal and work directory architecture under `$HOME`:
    - Flattened nested `~/Documents` into top-level domain roots: `~/projects`, `~/hardwire`, `~/notes`, `~/studia`, `~/archive`, `~/media`, and `~/workspaces`.
    - Updated `kickstart.sh` directory provisioning to create all 9 top-level domain folders on fresh install.
    - Updated `tmux` sessionizer (`sessionizer.sh`) to scan `~/projects`, `~/hardwire`, `~/studia`, `~/notes`, `~/workspaces`, and `~/.dotfiles` for instant `fzf` project fuzzy jumping.
  - Migrated music and DJ collection layout for Linux:
    - Moved DJ library root from `~/Music/dj` to `~/music`.
    - Renamed audio library directory from `music/` to `artists/` (`~/music/artists`).
    - Configured Beets `config.yaml` (`directory: ~/music/artists`, `library: ~/music/beetslibrary.blb`, `playlist_dir: ~/music/playlists`).
    - Fixed Beets `primary_artist` item_field regex to prevent mid-word separator truncation (e.g. `Daft Punk` -> `Da`).
    - Updated `kickstart.sh` directory provisioning to create `~/music/artists` and `~/music/playlists`.
    - Updated `spotatui` and `tui_app_run.fish` music path targets to `$HOME/music/artists`.
    - Updated `fish_variables` universal variable paths for `fish_user_paths` to `/home/semitechen/`.
    - Updated `darktablerc` import, collect, and plugin default paths to `/home/semitechen`.
  - Fully replaced `xdg-open` and `xdg-mime` with `handlr` (`handlr-regex`):
    - Added `handlr-regex` to `paru/.config/paru/packages.txt`.
    - Created `handlr` stow package with `~/.config/handlr/handlr.toml` enabling Rofi menu selector (`rofi -dmenu -i -p 'Open with:'`) when multiple handlers exist, and regex handler routing YouTube URLs directly to `mpv`.
    - Created executable wrappers `~/.local/bin/xdg-open` and `~/.local/bin/xdg-mime` (shadowing `xdg-utils` commands via user PATH precedence) mapping `xdg-open "$@"` to `handlr open "$@"` and translating `xdg-mime` subcommands (`default`, `query`) to `handlr set` and `handlr get`. Added safe fallback in `xdg-mime` to `/usr/bin/xdg-mime` for XML MIME registration commands (`install`, `uninstall`).
    - Configured default terminal environment: exported `TERMINAL=kitty`, `EDITOR=nvim`, and `VISUAL=nvim` in `xinit/.xinitrc` and `fish/config.fish`, and registered `x-scheme-handler/terminal` to `kitty.desktop` so CLI/TUI apps launched via `.desktop` files execute directly in Kitty.
    - Automated system-wide shadow wrapper `/usr/local/bin/xdg-open` and default file/protocol association registration (`inode/directory` -> `yazi.desktop`, `http[s]` -> `helium-browser.desktop`, `terminal` -> `kitty.desktop`) in `kickstart.sh`.
  - Configured touchpad clicks and natural scrolling for Framework 13:
    - Added `xf86-input-libinput` to `paru/.config/paru/packages.txt`.
    - Created `xorg/30-touchpad.conf` configuring `libinput` with tap-to-click (`Tapping on`), tap mapping (`TappingButtonMap lrm`: 1-finger left, 2-finger right, 3-finger middle), tap-and-drag (`TappingDrag true`), physical clickfinger (`ClickMethod clickfinger`), natural scrolling (`NaturalScrolling true`), two-finger scroll (`ScrollMethod twofinger`), palm rejection (`DisableWhileTyping true`), and standard button mapping `1 2 3 4 5 6 7`.
    - Updated `kickstart.sh` to automatically copy all `$DOTFILES_DIR/xorg/*.conf` configurations to `/etc/X11/xorg.conf.d/`.
  - Comprehensive configuration and bootstrap audit & bugfixes:
    - Added missing `iamb` and `ssh` packages to `STOW_PACKAGES` in `kickstart.sh`, added `mkdir -p ~/.ssh` with `0700` permissions, and set `0600` permissions for SSH config and VPN credential files.
    - Fixed `kitty.conf`: converted `background_image` to absolute path `/home/semitechen/.wallpapers/testbg.png` (fixing Kitty failing to expand `~`) and explicitly defined `font_family JetBrainsMono Nerd Font`.
    - Fixed `tmux.conf`: resolved `~` to absolute `/home/semitechen` and placed `~/.local/bin` ahead of `/usr/bin` so shadowing wrappers function properly in tmux sessions.
    - Updated `xinit/.xinitrc`: added `export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"` and `export GTK_USE_PORTAL=1` to ensure X11 apps inherit user binaries and route file dialogs to `xdg-desktop-portal`.
    - Fixed `portals.conf`: set `default=none` alongside `org.freedesktop.impl.portal.FileChooser=termfilechooser` to prevent portal crashes on unsupported interfaces.
    - Hardened `yazi-chooser` & `yazi.desktop`: added zero-byte placeholder touch and cancellation cleanup for save dialogs, and added `--class yazi` to `yazi.desktop`.
    - Hardened Fish shell & paru wrappers: added `paru` to `sudo.fish`, `config.fish`, and `__fish_paste.fish` to prevent fatal root execution errors, switched `paru` wrapper package lookups to exact column match in awk, and replaced `which fish` with `command -v fish`.
    - Added upfront `sudo -v` and background keep-alive loop to `kickstart.sh` so the script prompts for password once at startup and runs completely unattended without timeout pauses during package compilation.
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
  - Migrated Darktable SQLite `film_rolls.folder` database paths to `/home/semitechen`.
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
