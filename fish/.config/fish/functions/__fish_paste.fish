function __fish_paste --description "Translate pacman/yay to paru and paste clipboard text"
    # Automatically translate pacman or yay commands (with or without sudo) to paru on paste
    set -l input (string replace -ra '([;\|\&]+\s*|^)(sudo\s+)?(pacman|yay|paru)\b' '$1paru' -- $argv[1])

    # Split on \r and \n
    set -l data (string split \r -- $input | string split \n)
    set data (string replace -ra [[:cntrl:]] '' -- $data)

    if commandline --search-field >/dev/null
        commandline --search-field -i -- $data
        return
    end

    # If current token has an unmatched single-quote, escape single-quotes and backslashes
    set -l quote_state (__fish_tokenizer_state -- (commandline -ct | string collect))
    if contains -- $quote_state single single-escaped
        if status test-feature regex-easyesc
            set data (string replace -ra "(['\\\])" '\\\\$1' -- $data)
        else
            set data (string replace -ra "(['\\\])" '\\\\\\\$1' -- $data)
        end
    else if not contains -- $quote_state double double-escaped
        and set -q data[2]
        set -l tmp
        for line in $data
            switch $quote_state
                case normal
                    set -a tmp (string trim -l -- $line)
                case single single-escaped double double-escaped escaped
                    set -a tmp $line
            end
            set quote_state (__fish_tokenizer_state -i $quote_state -- $line)
        end
        set data $data[1] $tmp[2..]
    end

    if not string length -q -- (commandline -c)
        set data[1] (string trim -l -- $data[1])
    end

    if test -n "$data"
        commandline (
            if fish_is_root_user
                echo --insert
            else
                echo --insert-smart
            end
        ) -- $data
    end
end
