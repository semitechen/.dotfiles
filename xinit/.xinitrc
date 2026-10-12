#!/bin/sh

# Merge Xresources if available
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# Configure Polish keyboard layout with dual-Alt (both Left and Right Alt act as AltGr / Level 3 Switch)
# System-wide diacritics: ą, ć, ę, ł, ń, ó, ś, ź, ż
setxkbmap -layout pl -option lv3:alt_switch &

# Set standard cursor shape
xsetroot -cursor_name left_ptr &

# Restore wallpaper (stowed from ~/.wallpapers/)
if command -v feh >/dev/null 2>&1; then
    if [ -f "$HOME/.wallpapers/testbg.png" ]; then
        feh --bg-fill "$HOME/.wallpapers/testbg.png" &
    elif [ -f "$HOME/.dotfiles/wallpapers/.wallpapers/testbg.png" ]; then
        feh --bg-fill "$HOME/.dotfiles/wallpapers/.wallpapers/testbg.png" &
    fi
fi

# Start compositor for tear-free rendering and opacity
if command -v picom >/dev/null 2>&1; then
    picom -b &
fi

# dwm status bar updater
# Displays Battery and Date/Time in the top bar
dwm_status() {
    while true; do
        datetime=$(date "+%a %d %b %H:%M")

        bat=""
        for b in /sys/class/power_supply/BAT1 /sys/class/power_supply/BAT0; do
            if [ -d "$b" ]; then
                cap=$(cat "$b/capacity" 2>/dev/null)
                stat=$(cat "$b/status" 2>/dev/null)
                [ -n "$cap" ] && bat="[BAT ${cap}% ${stat}] "
                break
            fi
        done

        xsetroot -name "${bat}${datetime}"
        sleep 5
    done
}
dwm_status &

# Start dynamic window manager
exec dwm
