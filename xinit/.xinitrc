#!/bin/sh

[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export TERMINAL=kitty
export EDITOR=nvim
export VISUAL=nvim
export GTK_USE_PORTAL=1

setxkbmap -layout pl -option lv3:alt_switch &

xsetroot -cursor_name left_ptr &

if command -v feh >/dev/null 2>&1; then
    if [ -f "$HOME/.wallpapers/testbg.png" ]; then
        feh --bg-fill "$HOME/.wallpapers/testbg.png" &
    elif [ -f "$HOME/.dotfiles/wallpapers/.wallpapers/testbg.png" ]; then
        feh --bg-fill "$HOME/.dotfiles/wallpapers/.wallpapers/testbg.png" &
    fi
fi

# Compositor with all fading/animations disabled
if command -v picom >/dev/null 2>&1; then
    picom -b --config "$HOME/.config/picom/picom.conf" 2>/dev/null || picom -b --no-fading-openclose &
fi

if command -v dunst >/dev/null 2>&1; then
    dunst &
fi

# Autostart dedicated applications with genuine WM_CLASS for dwm tag rules:
# Tag 1 (Super+d): tmux (main terminal)
# Tag 2 (Super+a): aerc (email)
# Tag 3 (Super+s): spotatui (music)
# Tag 4 (Super+z): iamb (chat)
# Tag 5 (Super+x): helium (web browser)

# 1. Primary terminal running tmux session
if command -v kitty >/dev/null 2>&1; then
    kitty --class tmux tmux new-session -A -s main &
fi

# 2. Web browser (Helium)
if command -v helium-browser >/dev/null 2>&1; then
    helium-browser &
elif command -v helium >/dev/null 2>&1; then
    helium &
fi

# 3. Dedicated TUI applications
if command -v kitty >/dev/null 2>&1; then
    command -v aerc >/dev/null 2>&1 && kitty --class aerc aerc &
    command -v spotatui >/dev/null 2>&1 && kitty --class spotatui spotatui &
    command -v iamb >/dev/null 2>&1 && kitty --class iamb iamb &
fi

exec dwm
