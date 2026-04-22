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
stow fish nvim tmux gemini git
```

## Submodules

This repo uses submodules for specific configurations (e.g., `nvim`). To update:

```bash
git submodule update --init --recursive --remote
```

## Structure

- `fish/`: Shell configuration.
- `nvim/`: Neovim configuration (submodule).
- `tmux/`: Terminal multiplexer and plugins.
- `gemini/`: Gemini CLI (encrypted).
- `git/`: Git config.
- `wallpapers/`: System backgrounds.

## Security

Sensitive files defined in `.gitattributes` are encrypted at rest in the repository. Use `git-crypt export-key` to back up the master key.
