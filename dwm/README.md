# dwm Configuration for Arch Linux (Framework 13 Pro)

Customized suckless `dwm` configuration optimized for Framework 13 Pro laptop running Arch Linux.

## Key Features

- **`MODKEY = Mod4Mask`**: Uses the Super / Windows key as the modifier.
  - Prevents conflict with Polish diacritics: `AltGr + Shift + C` (or `Left Alt + Shift + C`) generates `Ć` cleanly without triggering window kill (`Super + Shift + C`).
- **Terminal**: `kitty` (`MODKEY + Return`).
- **Launcher**: `dmenu_run` (`MODKEY + p`) styled with Tokyo Night colors.
- **Hardware Keys**: Native bindings for WirePlumber volume controls (`wpctl`) and brightness (`brightnessctl`).
- **Typography & Colors**: Uses JetBrainsMono Nerd Font and Tokyo Night color palette matching Kitty, Neovim, Fish, and Tmux.

## Installation / Update

Run the included installer:
```bash
./install.sh
```

Or manually:
```bash
git clone https://git.suckless.org/dwm ~/.local/src/dwm
cp config.h ~/.local/src/dwm/config.h
cd ~/.local/src/dwm
sudo make clean install
```
