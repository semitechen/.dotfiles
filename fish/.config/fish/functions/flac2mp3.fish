function flac2mp3 --description 'Convert FLAC to MP3'
    set target $argv[1]
    
    if test -z "$target"
        set target "."
    end
    
    set -l flac_files
    
    if test -d "$target"
        set flac_files $target/*.flac
    else if test -f "$target"
        set flac_files "$target"
    else
        echo "Error: '$target' is not a valid file or directory."
        return 1
    end
    
    if not test -e "$flac_files[1]"
        echo "No FLAC files found to convert."
        return 1
    end
    
    # Auto-detect the number of CPU cores for maximum speed
    set -l cores 4
    if command -v nproc >/dev/null
        set cores (nproc)
    else if command -v sysctl >/dev/null
        set cores (sysctl -n hw.logicalcpu 2>/dev/null; or sysctl -n hw.ncpu 2>/dev/null; or echo 4)
    end
    
    echo "Found $cores CPU cores. Starting parallel conversion..."
    
    # Pass the list of files to xargs to handle parallel processing safely
    printf "%s\0" $flac_files | xargs -0 -n 1 -P $cores fish -c '
        set file $argv[1]
        set out_file (string replace -r -i "\.flac\$" ".mp3" "$file")
        
        echo "Converting: $file"
        
        # We add -n to ffmpeg so it skips existing files. 
        # If ffmpeg stops to ask "File exists. Overwrite? [y/N]", 
        # it will freeze the parallel background queue!
        ffmpeg -n -i "$file" -loglevel warning \
            -map 0:a:0 -map 0:v:0? \
            -c:a libmp3lame -q:a 0 \
            -c:v copy \
            -id3v2_version 3 \
            "$out_file"
    ' --
    
    echo "All conversions complete!"
end
