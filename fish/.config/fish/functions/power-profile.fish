function power-profile --description "Switch Framework 13 Pro power profile (ac, battery, or auto)"
    set -l target $argv[1]

    if test -z "$target"
        echo "Usage: power-profile [ac | battery | 60 | 120]"
        echo "  ac      : Set balanced profile, 120Hz display refresh rate"
        echo "  battery : Set balanced-battery profile, 60Hz display refresh rate"
        echo "  60      : Set display refresh rate to 60Hz"
        echo "  120     : Set display refresh rate to 120Hz"
        return 1
    end

    switch $target
        case ac perf 120
            echo ":: Activating AC Performance mode..."
            tuned-adm profile balanced
            if test -n "$DISPLAY"
                xrandr --output eDP-1 --mode 2880x1920 --rate 120.00 2>/dev/null
            end
            echo "✓ Set TuneD profile to 'balanced' and display to 120Hz."

        case bat battery save 60
            echo ":: Activating Battery Saver mode..."
            tuned-adm profile balanced-battery
            if test -n "$DISPLAY"
                xrandr --output eDP-1 --mode 2880x1920 --rate 60.00 2>/dev/null
            end
            echo "✓ Set TuneD profile to 'balanced-battery' and display to 60Hz."

        case '*'
            echo "Unknown profile target: $target. Choose 'ac' or 'battery'."
            return 1
    end
end
