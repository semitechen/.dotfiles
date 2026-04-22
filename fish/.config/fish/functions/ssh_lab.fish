function ssh_lab --argument-names port
    set -l target_port 2345
    if test -n "$port"
        set target_port $port
    end
    
    echo "Connecting to lab terminal on port $target_port..."
    
    ssh -Y -p $target_port -C -c aes128-ctr -o HostKeyAlgorithms=+ssh-rsa kjelonek@149.156.107.197
    
    echo "SSH session closed."
end
