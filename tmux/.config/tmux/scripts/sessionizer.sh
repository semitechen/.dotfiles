#!/usr/bin/env bash

# If a directory argument is provided, use it directly; otherwise use fzf to select
if [ $# -eq 1 ]; then
    selected=$1
else
    # Collect directories from zoxide and common paths
    dirs=()
    if command -v zoxide >/dev/null 2>&1; then
        while IFS= read -r line; do
            [ -d "$line" ] && dirs+=("$line")
        done < <(zoxide query -l 2>/dev/null)
    fi

    # Add standard project and config directories
    while IFS= read -r line; do
        [ -d "$line" ] && dirs+=("$line")
    done < <(find "$HOME/Documents" "$HOME/Downloads" "$HOME/.dotfiles" "$HOME/Music" -mindepth 1 -maxdepth 2 -type d 2>/dev/null)

    # Dedup and pick via fzf
    selected=$(printf '%s\n' "${dirs[@]}" | awk '!seen[$0]++' | fzf --reverse --prompt="⚡ Session > ")
fi

if [ -z "$selected" ]; then
    exit 0
fi

# Derive a clean session name
selected_name=$(basename "$selected" | tr . _ | tr ' ' _ | tr : _)

# Check if tmux server is running
tmux_running=$(pgrep tmux)

if [ -z "$TMUX" ] && [ -z "$tmux_running" ]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

# Create session if it doesn't exist
if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -d -s "$selected_name" -c "$selected"
fi

# Switch to the session
if [ -n "$TMUX" ]; then
    tmux switch-client -t "$selected_name"
else
    tmux attach-session -t "$selected_name"
fi
