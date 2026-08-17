# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/) and secured via [git-crypt](https://github.com/AGWA/git-crypt).

## Quick Start

```bash
# Clone with submodules
git clone --recursive <repo_url> ~/dotfiles
cd ~/dotfiles

# Unlock secrets (requires key)
git-crypt unlock /path/to/key

# Link packages
stow fish nvim tmux git aerc beets spotatui vpn wallpapers yazi

## Submodules

This repo uses submodules for specific configurations (e.g., `nvim`). To update:

```bash
git submodule update --init --recursive --remote
```

## Structure

- `aerc/`: TUI email client configuration.
- `beets/`: Music library management and DJ plugins.
- `fish/`: Shell configuration and utility functions.
- `git/`: Git configuration.
- `nvim/`: Neovim configuration (submodule).
- `spotatui/`: Spotify TUI client configuration.
- `tmux/`: Terminal multiplexer and plugins.
- `vpn/`: OpenVPN profiles and credentials (encrypted).
- `wallpapers/`: System backgrounds and new tab pages.
- `yazi/`: Terminal file manager configuration.

## Security

Sensitive files defined in `.gitattributes` are encrypted at rest in the repository. Use `git-crypt export-key` to back up the master key.
