#!/bin/sh

[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

export TERMINAL=kitty
export EDITOR=nvim
export VISUAL=nvim

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

# Autostart TUI applications under kitty using single-instance daemon mode.
# Sharing one GPU sprite cache, OpenGL context, and runtime drastically reduces RAM usage.
if command -v kitty >/dev/null 2>&1; then
    # 1. Primary daemon instance: main terminal with persistent tmux session (Super+d / Tag 1)
    kitty --single-instance --class tmux tmux new-session -A -s main &

    # 2. Wait briefly until kitty daemon socket is ready
    while ! pgrep -x kitty >/dev/null 2>&1; do
        sleep 0.1
    done
    sleep 0.2

    # 3. Spawn child TUI windows attaching to the single kitty master process
    command -v aerc >/dev/null 2>&1 && kitty --single-instance --class aerc aerc &
    command -v spotatui >/dev/null 2>&1 && kitty --single-instance --class spotatui spotatui &
    command -v iamb >/dev/null 2>&1 && kitty --single-instance --class iamb iamb &
fi

exec dwm
