function sudo --description "sudo wrapper intercepting pacman and yay to use paru safely"
    if test (count $argv) -gt 0
        switch $argv[1]
            case pacman yay
                # paru manages privileges internally and should not be run as root
                paru $argv[2..-1]
                return $status
        end
    end
    command sudo $argv
end
