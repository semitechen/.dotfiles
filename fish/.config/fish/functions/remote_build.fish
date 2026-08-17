function remote_build --argument-names port
    set -l target_port 10035
    if test -n "$port"
        set target_port $port
    end
    
    if test -f ./tools/remote_build.sh
        ./tools/remote_build.sh $target_port
    else
        echo "Error: ./tools/remote_build.sh not found. Make sure you are in the project root."
    end
end
