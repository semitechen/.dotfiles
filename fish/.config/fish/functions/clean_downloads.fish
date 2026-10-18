function clean_downloads --description 'Clean up files and folders in ~/Downloads older than 30 days via systemd-tmpfiles'
    if contains -- --dry-run $argv; or contains -- -n $argv
        echo "Dry run: previewing cleanup of items older than 30 days in ~/Downloads..."
        SYSTEMD_LOG_LEVEL=debug systemd-tmpfiles --user --clean
    else
        systemd-tmpfiles --user --clean
        echo "Cleaned files and folders in ~/Downloads older than 30 days."
    end
end
