# Dotfiles

Clean, minimalist, and distraction-free workstation environment for Arch Linux on Framework 13 Pro.

Managed with [GNU Stow](https://www.gnu.org/software/stow/) and secured at rest via [git-crypt](https://github.com/AGWA/git-crypt).

---

## Philosophy & Workflow

- **Window Management**: Custom build of [dwm](https://github.com/semitechen/dwm) — strictly tiled, borderless (`0px`), and status-bar free for complete focus.
- **Instant Responsiveness**: Zero animations, zero transitions, and zero fading across the compositor (`picom`), terminal, and applications.
- **Dedicated Workspaces**: Auto-started tags mapped to physical keys:
  - **Tag 1** (`Super+d`): Main terminal & persistent `tmux` session
  - **Tag 2** (`Super+a`): Email ([aerc](https://aerc-mail.org/))
  - **Tag 3** (`Super+s`): Music ([spotatui](https://github.com/marioortizmanero/spotatui))
  - **Tag 4** (`Super+z`): Matrix chat ([iamb](https://iamb.chat/))
  - **Tag 5** (`Super+x`): Web browser ([Helium](https://github.com/imputnet/helium))
  - **Tag 6** (`Super+q`): Hardware EDA ([KiCad](https://www.kicad.org/))
- **Keyboard Continuity**:
  - Full Polish diacritics with dual-Alt (Left Alt and Right Alt).
  - Fast buffer/tab navigation via `Alt+,` and `Alt+.` across Neovim, Kitty, Fish, aerc, and iamb.
  - Consistent terminal modifiers (`Ctrl+C` copy/interrupt, `Ctrl+V` paste, `Ctrl+T` new tmux window, `Ctrl+N` sessionizer).
- **Intelligent Package Auditing**: All installs through `paru` require a mandatory comment explaining their purpose, cleanly logged and tracked in `packages.txt`.
- **Dynamic Power Management**: Automated profile and display refresh rate switching for Framework 13 Pro (120Hz on AC, 60Hz + TuneD battery profile on battery) with `power-status` and `power-profile` terminal utilities.

---

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/semitechen/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Unlock sensitive secrets & configs
git-crypt unlock /path/to/dotfiles.key

# 3. Bootstrap entire system (installs packages, stows configs, enables services)
./kickstart.sh
```

---

## Repository Structure

| Package | Purpose |
| :--- | :--- |
| `aerc/` | Terminal email client configured for IMAP/SMTP accounts with image & HTML filters |
| `beets/` | Music cataloger, acoustic analyzer, and DJ playlist management plugins |
| `darktable/` | Non-destructive RAW photography workflow and custom camera styles |
| `easyeffects/` | Speaker DSP tuning for Framework 13 Pro (IRS convolution, autoloading, systemd daemon) |
| `fastfetch/` | Minimalist system information fetch tool styled in Tokyo Night |
| `fish/` | Interactive shell with autosuggestions, git prompt, and paru command translation |
| `gemini/` | Gemini CLI & Antigravity configuration, MCP servers, and custom skills |
| `gh/` | GitHub CLI configuration and authenticated credentials (encrypted) |
| `git/` | Global Git configuration, default branch naming, and diff/merge helpers |
| `handlr/` | High-performance system opener routing MIME types and URLs to dedicated tools |
| `helium/` | Lightweight Chromium browser configuration and VA-API hardware video flags |
| `iamb/` | Terminal Matrix chat client configured with Tokyo Night palette |
| `kitty/` | GPU-accelerated terminal with JetBrainsMono Nerd Font & CJK fallback glyphs |
| `nvim/` | Modal configuration in Lua managed with `lazy.nvim`, Treesitter, and Mason LSPs |
| `paru/` | Paru package manager wrapper enforcing reason comments logged into `packages.txt` |
| `picom/` | Lightweight GLX compositor configured for tear-free instant rendering |
| `rofi/` | Application launcher and window switcher in Tokyo Night palette |
| `spotatui/` | Lightweight terminal Spotify client with MPRIS daemon integration |
| `ssh/` | SSH client host configurations and hardware key definitions (encrypted) |
| `systemd/` | User-level systemd units, cleanup timers, and Btrfs suspend-then-hibernate automation |
| `tmux/` | Terminal multiplexer with TPM plugins, Tokyo Night powerline, and fuzzy project switcher |
| `udev/` | Framework 13 Pro power management rules, dynamic refresh rate switcher, and Wi-Fi powersave |
| `vpn/` | OpenVPN profiles and secure network configurations (encrypted) |
| `wallpapers/` | Minimal system wallpapers and local browser assets |
| `xinit/` | X11 initialization (`~/.xinitrc`), HiDPI cursor scaling, and tag autostarts |
| `xorg/` | System-wide X11 snippets: Polish dual-Alt layout, touchpad gestures, and hardware VRR |
| `yazi/` | Terminal file manager with image previews, integrated as GUI file chooser portal |

---

## Security

Sensitive files (SSH configurations, personal API keys, VPN tunnels, and credentials) specified in `.gitattributes` are encrypted at rest with `git-crypt`. Use `git-crypt export-key <path>` to back up keys securely.
