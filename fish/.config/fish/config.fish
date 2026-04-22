if status is-interactive
# Commands to run in interactive sessions can go here
	zoxide init --cmd cd fish | source
end

set -gx LC_TIME en_US.UTF-8

source ~/.config/fish/conf.d/tokyonight_night.fish
