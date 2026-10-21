if status is-interactive
	# Commands to run in interactive sessions can go here
	zoxide init --cmd cd fish | source

	# Automatically translate pacman/yay commands to paru before execution
	function __auto_translate_pacman_yay
		set -l cmd (commandline)
		set -l translated (string replace -ra '([;\|\&]+\s*|^)(sudo\s+)?(pacman|yay|paru)\b' '$1paru' -- "$cmd")
		if test "$cmd" != "$translated"
			commandline -r -- "$translated"
		end
		commandline -f execute
	end

	bind \r __auto_translate_pacman_yay
	bind \n __auto_translate_pacman_yay

	# Muscle memory token search (Alt+. and Alt+, and raw Polish AltGr fallbacks)
	bind \e. history-token-search-backward
	bind \e, history-token-search-forward
	bind \e\x2e history-token-search-backward
	bind \e\x2c history-token-search-forward
	bind ≤ history-token-search-forward
	bind ≥ history-token-search-backward
end

set -gx LC_TIME en_US.UTF-8
set -gx TERMINAL kitty
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx GTK_USE_PORTAL 1

source ~/.config/fish/conf.d/tokyonight_night.fish


# User binaries
set -gx PATH "$HOME/.local/bin" "$HOME/.cargo/bin" $PATH
