# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/) and secured via [git-crypt](https://github.com/AGWA/git-crypt).

## Quick Start

```bash
# Clone dotfiles
git clone <repo_url> ~/.dotfiles
cd ~/.dotfiles
git checkout arch

# Unlock secrets (requires key exported from previous machine)
git-crypt unlock /path/to/dotfiles.key

# Automated system bootstrap (installs packages, stows configs, enables services)
./kickstart.sh
```

## Structure

- `aerc/`: TUI email client configuration.
- `beets/`: Music library management and DJ plugins.
- `darktable/`: Photography workflow, custom styles, shortcuts, and configuration.
- `fish/`: Shell configuration and utility functions.
- `gemini/`: Gemini / Antigravity CLI configuration, MCP servers, and custom skills.
- `gh/`: GitHub CLI configuration and credentials (encrypted).
- `git/`: Git configuration.
- `kitty/`: Terminal emulator configuration.
- `nvim/`: Neovim configuration.
- `paru/`: Package management wrapper enforcing mandatory comments into `packages.txt`, with pacman/yay redirection.
- `rofi/`: Application launcher, command runner, and window switcher in Tokyo Night palette (replacing Raycast).
- `spotatui/`: Spotify TUI client configuration.
- `tmux/`: Terminal multiplexer and plugins.
- `vpn/`: OpenVPN profiles and credentials (encrypted).
- `wallpapers/`: System backgrounds and new tab pages.
- `xinit/`: X11 session initialization (`~/.xinitrc`, dual-Alt Polish layout).
- `xorg/`: System-wide X11 configuration snippets (`00-keyboard.conf`).
- `yazi/`: Terminal file manager configuration.

## Security

Sensitive files defined in `.gitattributes` are encrypted at rest in the repository. Use `git-crypt export-key` to back up the master key.
