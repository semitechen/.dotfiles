function merge_missing_tracks
    # Parse options for a dry-run flag
    set -l options 'h/help' 'd/dry-run'
    argparse $options -- $argv
    or return
    
    if set -q _flag_help
        echo "Usage: merge_missing_tracks [-d|--dry-run] <high_quality_dir> <ytdlp_dir>"
        return 0
    end
    
    if test (count $argv) -lt 2
        echo "Error: Please provide both the HQ and YT-DLP directories."
        echo "Usage: merge_missing_tracks [-d|--dry-run] <high_quality_dir> <ytdlp_dir>"
        return 1
    end
    
    set hq_dir $argv[1]
    set yt_dir $argv[2]
    
    # Grab HQ files and pre-process their words to save time
    set -l hq_files (find "$hq_dir" -type f -iname "*.mp3")
    set -l hq_names_clean
    
    echo "Indexing high-quality files..."
    for hq_file in $hq_files
        set -l filename (basename "$hq_file")
        # Remove extension and lowercase
        set -l clean (string lower "$filename" | string replace -ri '\.mp3$' '')
        set -a hq_names_clean "$clean"
    end
    
    # Grab YT files from all subfolders
    set -l yt_files (find "$yt_dir" -type f -iname "*.mp3")
    
    echo "Comparing yt-dlp files against high-quality files (Word Match)..."
    echo "----------------------------------------------------"
    
    for yt_file in $yt_files
        set -l filename (basename "$yt_file")
        
        # Clean YT filename: remove .mp3, and strip fluff inside [] or ()
        set -l clean_yt (string lower "$filename" | string replace -ri '\.mp3$' '' | string replace -ra '\[.*?\]|\(.*?\)' '')
        
        # Split into an array of individual alphanumeric words
        set -l yt_words (string match -ra '[a-z0-9]+' "$clean_yt")
        set -l yt_word_count (count $yt_words)
        
        if test $yt_word_count -eq 0
            continue
        end
        
        set -l found 0
        
        for hq_name in $hq_names_clean
            # Split HQ name into an array of words
            set -l hq_words (string match -ra '[a-z0-9]+' "$hq_name")
            set -l hq_word_count (count $hq_words)
            
            if test $hq_word_count -eq 0
                continue
            end
            
            # Count how many YT words are found in the HQ words array
            set -l match_count 0
            for yt_word in $yt_words
                if contains -- "$yt_word" $hq_words
                    set match_count (math $match_count + 1)
                end
            end
            
            # THE FIX: Integer math. 
            # Multiply by 100 and 70 to avoid decimals, then use standard integer 'test -ge' (greater than or equal)
            set -l match_score (math "$match_count * 100")
            set -l yt_threshold (math "$yt_word_count * 70")
            set -l hq_threshold (math "$hq_word_count * 70")
            
            if test $match_score -ge $yt_threshold; or test $match_score -ge $hq_threshold
                set found 1
                break
            end
        end
        
        if test $found -eq 0
            if set -q _flag_dry_run
                set_color yellow
                echo "[DRY RUN] Would move: $filename"
                set_color normal
            else
                set_color green
                echo "Moving missing track: $filename"
                set_color normal
                mv "$yt_file" "$hq_dir/"
            end
        end
    end
    echo "----------------------------------------------------"
    echo "Done!"
end
