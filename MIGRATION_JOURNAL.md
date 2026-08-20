# macOS to Arch Linux Migration Journal & Checklist

This document tracks all system differences, required configuration tweaks, and setup steps when transitioning from macOS to an Arch Linux laptop.

---

## 1. System Differences & Compatibility Tracker

| Category | macOS (Current) | Arch Linux (Target) | Status in Dotfiles |
| :--- | :--- | :--- | :--- |
| **System Openers** | `/usr/bin/open` | `xdg-open` | ℹ️ **Note**: Standard Linux file/URL opener is `xdg-open`. |
| **URL Opening in Terminal** | `Shift + Click` (or `Shift + Cmd + Click`) / `Ctrl + Shift + e` (Hints) | `Shift + Click` / `Ctrl + Shift + e` (Hints) | ✅ **Handled**: Kitty built-in URL handling bypasses terminal app mouse grabs (`aerc`, `nvim`). |
| **Clipboard** | `pbcopy` / `pbpaste` | `wl-copy` / `wl-paste` (Wayland) or `xclip` (X11) | ⚠️ **Action Needed**: Replace any custom shell aliases using `pbcopy`. |
| **Terminal Modifiers** | `cmd+t`, `cmd+w`, `cmd+n` in `kitty.conf` | `alt+...` or `super+...` | ⚠️ **Action Needed**: Update keybindings in `kitty.conf` on Linux. |
| **macOS Options** | `macos_option_as_alt yes` | Not applicable | ⚠️ **Action Needed**: Clean from `kitty.conf`. |
| **Launcher** | `raycast/` (macOS-only) | `rofi-wayland`, `fuzzel`, `tofi`, or `anyrun` | ℹ️ **Action Needed**: Do not stow `raycast` on Linux; configure Linux launcher. |
| **Shell Paths** | `fish_variables` has `/opt/homebrew` | Standard `/usr/bin`, `~/.local/bin`, `~/.cargo/bin` | ⚠️ **Action Needed**: Reset `fish_user_paths` (`set -e fish_user_paths`). |
| **Tmux Plugins** | TPM manual bootstrap | Auto-bootstrapping script in `tmux.conf` | ✅ **Handled**: Auto-clones and installs plugins on launch. |
| **Tmux Sessionizer** | `fzf` + `zoxide` popup | `fzf` + `zoxide` popup | ✅ **Handled**: Portable script at `tmux/scripts/sessionizer.sh`. |
| **Neovim** | `lazy.nvim` with `lazy-lock.json` | `lazy.nvim` with `lazy-lock.json` | ✅ **Handled**: Auto-downloads plugins to `~/.local/share/nvim/lazy/`. |
| **Gemini / Antigravity** | `settings.json` + `config/` | `settings.json` + `config/` | ✅ **Handled**: Zero local paths in git; symlinked via `stow gemini`. |

---

## 2. Arch Linux Package Installation List

When setting up the new Arch laptop, install these core packages:

```bash
# Core CLI Tools, Shell, & Multiplexer
sudo pacman -S git git-crypt stow fish tmux neovim zoxide fzf ripgrep fd yazi

# Terminal & GUI Tools
sudo pacman -S kitty

# Node & Python (Required for Gemini MCP servers & custom skills)
sudo pacman -S nodejs npm python python-pip

# Audio & Mail Tools
sudo pacman -S aerc beets w3m openvpn

# Fonts (Nerd Fonts required for icons in tmux, kitty, & yazi)
sudo pacman -S ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
```

---

## 3. Fresh Arch Setup Recipe

1. **Clone Dotfiles**:
   ```bash
   git clone <repo_url> ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Unlock Secrets**:
   ```bash
   git-crypt unlock /path/to/exported-dotfiles.key
   ```

3. **Stow Desired Packages** (skip macOS-only `raycast`):
   ```bash
   stow fish nvim tmux git aerc beets spotatui vpn wallpapers yazi gemini kitty
   ```

4. **Initialize Shell & Plugins**:
   - **Fish**: Launch `fish` and let `zoxide` initialize.
   - **Tmux**: Launch `tmux` (TPM will automatically install `tmux-resurrect`, `tmux-continuum`, and `tmux-powerline`).
   - **Neovim**: Open `nvim` (Lazy.nvim will automatically sync all plugins).
   - **Antigravity CLI**: Install `agy` Linux binary and run `agy` once to complete authentication.

---

## 4. Post-Migration Notes & Tweaks Log

- **2026-08-20**:
  - Replaced submodules with manifest-driven plugin management (`lazy-lock.json` and TPM auto-install).
  - Added portable `sessionizer.sh` for instant project switching (`fzf` + `zoxide` on `cmd+n` / `prefix+N`).
  - Stripped local workspace paths from `settings.json` and gitignored `gemini/projects/`.
