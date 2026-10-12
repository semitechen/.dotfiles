# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/) and secured via [git-crypt](https://github.com/AGWA/git-crypt).

## Quick Start

```bash
# Clone dotfiles
git clone <repo_url> ~/.dotfiles
cd ~/.dotfiles

# Unlock secrets (requires key)
git-crypt unlock /path/to/key

# Link packages
stow fish nvim tmux git aerc beets spotatui vpn wallpapers yazi gemini kitty gh darktable
```

## Structure

- `aerc/`: TUI email client configuration.
- `beets/`: Music library management and DJ plugins.
- `darktable/`: Photography workflow, custom styles, shortcuts, and databases (encrypted).
- `fish/`: Shell configuration and utility functions.
- `gemini/`: Gemini / Antigravity CLI configuration, MCP servers, and custom skills.
- `gh/`: GitHub CLI configuration and credentials (encrypted).
- `git/`: Git configuration.
- `kitty/`: Terminal emulator configuration.
- `nvim/`: Neovim configuration.
- `spotatui/`: Spotify TUI client configuration.
- `tmux/`: Terminal multiplexer and plugins.
- `vpn/`: OpenVPN profiles and credentials (encrypted).
- `wallpapers/`: System backgrounds and new tab pages.
- `yazi/`: Terminal file manager configuration.

## Security

Sensitive files defined in `.gitattributes` are encrypted at rest in the repository. Use `git-crypt export-key` to back up the master key.
