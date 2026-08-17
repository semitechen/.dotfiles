function vpn --description 'Connect to a VPN server by name'
    if test (count $argv) -eq 0
        echo "Error: No VPN server name provided."
        echo "Usage: vpn [server_name] (e.g., vpn pl-231)"
        return 1
    end

    set -l server_name $argv
    set -l all_configs ~/.vpn/*/*.ovpn
    set -l config_files

    for file in $all_configs
        if string match -qi "*$server_name*" (basename $file)
            set -a config_files $file
        end
    end

    if test (count $config_files) -eq 0
        echo "Error: No configuration file found for '$server_name' in ~/.vpn/."
        return 1
    elif test (count $config_files) -gt 1
        echo "Error: Multiple matching files found:"
        for file in $config_files
            echo "  - "(string replace "$HOME/.vpn/" "" $file)
        end
        echo "Please specify a more precise server name."
        return 1
    end

    set -l target_config $config_files
    set -l config_dir (dirname $target_config)
    set -l auth_file "$config_dir/creds"

    if not test -f $auth_file
        echo "Error: Credentials file not found at $auth_file"
        return 1
    end

    echo "Using credentials from: "(string replace "$HOME/.vpn/" "" $auth_file)
    echo "Connecting to VPN using: "(basename $target_config)"..."

    set -l openvpn_bin "openvpn"
    if command -v brew >/dev/null; and test -x (brew --prefix)/sbin/openvpn
        set openvpn_bin (brew --prefix)/sbin/openvpn
    end

    sudo $openvpn_bin --config $target_config --auth-user-pass $auth_file

    echo "Disconnecting and cleanup"
    if test (uname) = "Darwin"
        sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder 2>/dev/null
    else if command -v resolvectl >/dev/null
        sudo resolvectl flush-caches 2>/dev/null
    else if command -v systemctl >/dev/null; and systemctl is-active --quiet systemd-resolved 2>/dev/null
        sudo systemctl restart systemd-resolved 2>/dev/null
    end
end
