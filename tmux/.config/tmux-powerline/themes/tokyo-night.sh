# shellcheck shell=bash
# Default Theme
# If changes made here does not take effect, then try to re-create the tmux session to force reload.

if tp_patched_font_in_use; then
    TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=""
    TMUX_POWERLINE_SEPARATOR_LEFT_THIN=""
    TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=""
    TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=""
else
	TMUX_POWERLINE_SEPARATOR_LEFT_BOLD="◀"
	TMUX_POWERLINE_SEPARATOR_LEFT_THIN="❮"
	TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="▶"
	TMUX_POWERLINE_SEPARATOR_RIGHT_THIN="❯"
fi

# -------------------------------------------------------------------
# TOKYONIGHT BASE COLORS
# -------------------------------------------------------------------
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-'#16161e'}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-'#a9b1d6'}
# shellcheck disable=SC2034
TMUX_POWERLINE_SEG_AIR_COLOR=$(tp_air_color)

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_CURRENT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
		"#[$(tp_format inverse)]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
		" #I#F "
		"$TMUX_POWERLINE_SEPARATOR_RIGHT_THIN"
		" #W "
		"#[$(tp_format regular)]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_STYLE" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_STYLE=(
		"$(tp_format regular)"
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_FORMAT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
		"#[$(tp_format regular)]"
		"  #I#{?window_flags,#F, } "
		"$TMUX_POWERLINE_SEPARATOR_RIGHT_THIN"
		" #W "
	)
fi

# -------------------------------------------------------------------
# LEFT STATUS SEGMENTS (TokyoNight Palette)
# -------------------------------------------------------------------
# Format: segment_name [bg_color] [fg_color] [separator] ...

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_LEFT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
		"tmux_session_info #7aa2f7 #15161e"   # Blue accent, dark text
		#"hostname #3b4261 #7aa2f7"            # Lighter bg, blue text
		#"mode_indicator 165 0"
		#"ifstat 30 255"
		#"ifstat_sys 30 255"
		#"lan_ip #16161e #a9b1d6 " # Base bg, text fg
		#"vpn 24 255 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}"
		#"wan_ip #16161e #a9b1d6"
		#"vcs_branch #3b4261 #e0af68"          # Lighter bg, orange accent
		#"vcs_compare 60 255"
		#"vcs_staged 64 255"
		#"vcs_modified 9 255"
		#"vcs_others 245 0"
	)
fi

# -------------------------------------------------------------------
# RIGHT STATUS SEGMENTS (TokyoNight Palette)
# -------------------------------------------------------------------

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		#"earthquake 3 0"
		"pwd #3b4261 #a9b1d6"                 # Lighter bg, text fg
		#"macos_notification_count 29 255"
		#"mailcount 9 255"
		"now_playing 234 37"
		#"cpu 240 136"
		#"load #16161e #7aa2f7"               # Base bg, blue text
		#"tmux_mem_cpu_load 234 136"
		"battery #16161e #e0af68"             # Base bg, orange accent
		#"air ${TMUX_POWERLINE_SEG_AIR_COLOR} 255"
		
		# Disabled the separator here so weather flows cleanly next to battery
		"weather #16161e #a9b1d6 default_separator no_sep_bg_color no_sep_fg_color none separator_disable"
		
		#"rainbarf 0 ${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR}"
		
		# Removed the thin separator override so it uses the thick  to transition colors safely
		"date #3b4261 #7aa2f7"
		
		# Disabled the separator entirely so Time sits naturally next to Date
		"time #3b4261 #7aa2f7 default_separator no_sep_bg_color no_sep_fg_color left_disable separator_disable" 
		
		#"utc_time 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
	)
fi
