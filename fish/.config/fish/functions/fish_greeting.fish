function fish_greeting --description 'Display Arch Linux fastfetch greeting with Tokyo Night styling'
    if command -v fastfetch >/dev/null 2>&1
        fastfetch
    end
end
