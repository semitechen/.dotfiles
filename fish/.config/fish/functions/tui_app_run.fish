function tui_app_run --description 'Run a TUI application in an auto-restarting loop from HOME'
    if test (count $argv) -eq 0
        echo "Usage: tui_app_run <command> [args...]"
        return 1
    end

    if not command -v $argv[1] >/dev/null 2>&1
        echo "Error: Command '$argv[1]' not found in PATH."
        return 1
    end

    set -l prev_dir $PWD
    builtin cd $HOME

    set -l app $argv[1]
    set -l app_args $argv[2..-1]

    if test "$app" = "spotatui"
        set -l spotatui_cfg "$HOME/.config/spotatui/config.yml"
        if test -f "$spotatui_cfg"
            sed -i.bak -E "s|([ ]*local_music_path:)[ ]*.*|\1 $HOME/Music/dj/music|" "$spotatui_cfg" 2>/dev/null; and rm -f "$spotatui_cfg.bak"
        end
    end

    while true
        $app $app_args
        set -l exit_code $status

        if test $exit_code -eq 130
            break
        end

        echo (set_color yellow)"[$app] Stopped (exit code $exit_code). Restarting in 1s... (Ctrl+C to stop)"(set_color normal)
        sleep 1; or break
    end

    builtin cd $prev_dir
end
