#!/bin/sh

[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

setxkbmap -layout pl -option lv3:alt_switch &

xsetroot -cursor_name left_ptr &

if command -v feh >/dev/null 2>&1; then
    if [ -f "$HOME/.wallpapers/testbg.png" ]; then
        feh --bg-fill "$HOME/.wallpapers/testbg.png" &
    elif [ -f "$HOME/.dotfiles/wallpapers/.wallpapers/testbg.png" ]; then
        feh --bg-fill "$HOME/.dotfiles/wallpapers/.wallpapers/testbg.png" &
    fi
fi

if command -v picom >/dev/null 2>&1; then
    picom -b &
fi

exec dwm
