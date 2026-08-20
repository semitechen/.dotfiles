# shellcheck shell=bash
# Prints the current weather in Celsius, Fahrenheits or lord Kelvins using Nerd Font icons.
# Sourced from user segments for crisp rendering.

# shellcheck source=lib/util.sh
source "${TMUX_POWERLINE_DIR_LIB}/util.sh"

TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER_DEFAULT="yrno"
TMUX_POWERLINE_SEG_WEATHER_UNIT_DEFAULT="c"
TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD_DEFAULT="600"
TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD_DEFAULT="86400" # 24 hours
TMUX_POWERLINE_SEG_WEATHER_LAT_DEFAULT="auto"
TMUX_POWERLINE_SEG_WEATHER_LON_DEFAULT="auto"

# Global cache file for weather data
TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_WEATHER="${TMUX_POWERLINE_DIR_TEMPORARY}/weather_cache_data.txt"
TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_LOCATION="${TMUX_POWERLINE_DIR_TEMPORARY}/weather_cache_location.txt"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
export TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER="${TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER_DEFAULT}"
export TMUX_POWERLINE_SEG_WEATHER_UNIT="${TMUX_POWERLINE_SEG_WEATHER_UNIT_DEFAULT}"
export TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD="${TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD_DEFAULT}"
export TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD="${TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD_DEFAULT}"
export TMUX_POWERLINE_SEG_WEATHER_LAT="${TMUX_POWERLINE_SEG_WEATHER_LAT_DEFAULT}"
export TMUX_POWERLINE_SEG_WEATHER_LON="${TMUX_POWERLINE_SEG_WEATHER_LON_DEFAULT}"
EORC
	echo "$rccontents"
}

run_segment() {
	local weather=""
	weather=$(__weather_cache_read)

	if [ -z "$weather" ]; then
		__process_settings
		case "$TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER" in
		"yrno")
			weather=$(__yrno)
			;;
		*)
			tp_err_seg "Err: Invalid weather data provider: ${TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER}"
			return 1
			;;
		esac

		__weather_cache_write "$weather"
	fi

	echo "$weather"
}

__process_settings() {
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER="${TMUX_POWERLINE_SEG_WEATHER_DATA_PROVIDER_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_UNIT" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_UNIT="${TMUX_POWERLINE_SEG_WEATHER_UNIT_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD="${TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD" ]; then
		export TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD="${TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD_DEFAULT}"
	fi
	if [ "$TMUX_POWERLINE_SEG_WEATHER_LAT" = "auto" ] || [ "$TMUX_POWERLINE_SEG_WEATHER_LON" = "auto" ] || [ -z "$TMUX_POWERLINE_SEG_WEATHER_LON" ] || [ -z "$TMUX_POWERLINE_SEG_WEATHER_LAT" ]; then
		if ! __get_auto_location; then
			exit 8
		fi
	fi
}

__yrno() {
	if ! command -v curl >/dev/null 2>&1; then
		tp_err_seg "Err: curl not installed"
		return 1
	fi
	if ! command -v jq >/dev/null 2>&1; then
		tp_err_seg "Err: jq not installed"
		return 1
	fi

	local degree=""
	if [ -z "$TMUX_POWERLINE_SEG_WEATHER_LAT" ] || [ -z "$TMUX_POWERLINE_SEG_WEATHER_LON" ]; then
		tp_err_seg "Err: Unable to auto-detect your location"
		return 1
	fi

	local user_agent
	user_agent="tmux-powerline/$(tp_version) (https://github.com/erikw/tmux-powerline)"

	if weather_data=$(curl --max-time 4 -A "$user_agent" -s "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${TMUX_POWERLINE_SEG_WEATHER_LAT}&lon=${TMUX_POWERLINE_SEG_WEATHER_LON}"); then
		error=$(echo "$weather_data" | grep -i "error")
		if [ -n "$error" ]; then
			tp_err_seg "Err: yr.no err: error in api return"
			return 1
		fi
		degree=$(echo "$weather_data" | jq -r '.properties.timeseries | .[0].data.instant.details.air_temperature')
		condition=$(echo "$weather_data" | jq -r '.properties.timeseries | .[0].data.next_1_hours.summary.symbol_code')
	fi

	if [ -z "$degree" ]; then
		tp_err_seg "Err: yr.no err: unable to fetch weather data"
		return 1
	fi

	if [ "$TMUX_POWERLINE_SEG_WEATHER_UNIT" = "k" ]; then
		degree=$(__degree_c2k "$degree")
	fi
	if [ "$TMUX_POWERLINE_SEG_WEATHER_UNIT" = "f" ]; then
		degree=$(__degree_c2f "$degree")
	fi

	condition_symbol=$(__get_yrno_condition_symbol "$condition")
	echo "${condition_symbol} ${degree}°$(echo "$TMUX_POWERLINE_SEG_WEATHER_UNIT" | tr '[:lower:]' '[:upper:]')"
}

__degree_c2k() {
	local c="$1"
	echo "${c} + 273.15" | bc
}

__degree_c2f() {
	local c="$1"
	echo "${c} * 9 / 5 + 32" | bc
}

# Map Yr.no symbol codes to crisp Nerd Font weather icons
__get_yrno_condition_symbol() {
	local condition=$1
	case "$condition" in
	"clearsky_day")
		echo "󰖙"
		;;
	"clearsky_night")
		echo "󰖔"
		;;
	"fair_day" | "partlycloudy_day")
		echo "󰖕"
		;;
	"fair_night" | "partlycloudy_night")
		echo "󰼱"
		;;
	"fog")
		echo "󰖑"
		;;
	"cloudy")
		echo "󰖐"
		;;
	"rain" | "lightrain" | "rainshowers_day" | "rainshowers_night")
		echo "󰖖"
		;;
	"heavyrain" | "heavyrainshowers_day" | "heavyrainshowers_night")
		echo "󰖗"
		;;
	"heavyrainandthunder" | "heavyrainshowersandthunder_day" | "heavyrainshowersandthunder_night" | \
	"lightrainandthunder" | "lightrainshowersandthunder_day" | "lightrainshowersandthunder_night" | \
	"rainandthunder" | "rainshowersandthunder_day" | "rainshowersandthunder_night")
		echo "󰖓"
		;;
	"sleet" | "lightsleet" | "heavysleet" | "sleetshowers_day" | "sleetshowers_night" | \
	"sleetandthunder" | "sleetshowersandthunder_day" | "sleetshowersandthunder_night")
		echo "󰙾"
		;;
	"snow" | "lightsnow" | "heavysnow" | "lightsnowshowers_day" | "lightsnowshowers_night" | \
	"heavysnowshowers_day" | "heavysnowshowers_night" | "snowshowers_day" | "snowshowers_night" | \
	"snowandthunder" | "snowshowersandthunder_day" | "snowshowersandthunder_night")
		echo "󰖘"
		;;
	*)
		echo "󰖐"
		;;
	esac
}

__read_file_split() {
	file_to_read="$1"
	lookup_index="$2"
	fallback_value="$3"
	if [ ! -f "$file_to_read" ]; then
		echo "$fallback_value"
		return
	fi
	local -a file_arr
	IFS='@' read -ra file_arr <<< "$(cat "$file_to_read")"
	if [ -z "${file_arr[$lookup_index]}" ]; then
		echo "$fallback_value"
		return
	fi
	echo "${file_arr[$lookup_index]}"
}

__read_file_content() {
	__read_file_split "$1" 0 ""
}

__read_file_last_update() {
	__read_file_split "$1" 1 0
}

__weather_cache_read() {
	local last_update time_now up_to_date
	if [ ! -f "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_WEATHER" ]; then
		echo ""
		return
	fi
	last_update=$(__read_file_last_update "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_WEATHER")
	time_now=$(date +%s)
	up_to_date=$(echo "(${time_now}-${last_update}) < ${TMUX_POWERLINE_SEG_WEATHER_UPDATE_PERIOD}" | bc)
	if [ "$up_to_date" -eq 1 ]; then
		__read_file_content "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_WEATHER"
	else
		echo ""
	fi
}

__write_to_file_with_last_updated() {
	local file_to_write="$1"
	local content="$2"
	if [ -z "$content" ]; then
		return
	fi
	printf '%s@%s\n' "$content" "$(date +%s)" > "$file_to_write"
}

__weather_cache_write() {
	local content="$1"
	if [ -n "$content" ]; then
		__write_to_file_with_last_updated "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_WEATHER" "$content"
	else
		tp_err_seg "Err: Failed to fetch weather data, caching error message to avoid repeated fetch attempts"
		__write_to_file_with_last_updated "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_WEATHER" "failed to fetch weather data"
	fi
}

__get_auto_location() {
    local max_cache_age=$TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD
    local -a lat_lon_arr

    if [[ -f "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_LOCATION" ]]; then
        local cache_age=$(($(date +%s) - $(__read_file_last_update "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_LOCATION")))
        if (( cache_age < max_cache_age )); then
            IFS=' ' read -ra lat_lon_arr <<< "$(__read_file_content "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_LOCATION")"
            TMUX_POWERLINE_SEG_WEATHER_LAT=${lat_lon_arr[0]}
            TMUX_POWERLINE_SEG_WEATHER_LON=${lat_lon_arr[1]}
            if [[ -n "$TMUX_POWERLINE_SEG_WEATHER_LAT" && -n "$TMUX_POWERLINE_SEG_WEATHER_LON" ]]; then
                return 0
            fi
        fi
    fi

    local location_data
    for api in "https://ipinfo.io/json" "https://ipapi.co/json"; do
        if location_data=$(curl --max-time 4 -s "$api"); then
            case "$api" in
                *ipinfo.io*)
                    IFS=',' read -ra loc <<< "$(echo "$location_data" | jq -r '.loc')"
                    TMUX_POWERLINE_SEG_WEATHER_LAT="${loc[0]}"
                    TMUX_POWERLINE_SEG_WEATHER_LON="${loc[1]}"
                    ;;
                *ipapi.co*)
                    TMUX_POWERLINE_SEG_WEATHER_LAT=$(echo "$location_data" | jq -r '.latitude')
                    TMUX_POWERLINE_SEG_WEATHER_LON=$(echo "$location_data" | jq -r '.longitude')
                    ;;
            esac

            if [[ -z "$TMUX_POWERLINE_SEG_WEATHER_LAT" ||
                  -z "$TMUX_POWERLINE_SEG_WEATHER_LON" ||
                  "$TMUX_POWERLINE_SEG_WEATHER_LAT" == "null" ||
                  "$TMUX_POWERLINE_SEG_WEATHER_LON" == "null" ]]; then
                continue
            fi

            __write_to_file_with_last_updated "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_LOCATION" "$TMUX_POWERLINE_SEG_WEATHER_LAT $TMUX_POWERLINE_SEG_WEATHER_LON"
            return 0
        fi
    done

    if [[ -f "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_LOCATION" ]]; then
        tp_err_seg "Warn: Using stale location data (failed to refresh)"
        IFS=' ' read -ra lat_lon_arr <<< "$(__read_file_content "$TMUX_POWERLINE_SEG_WEATHER_CACHE_FILE_LOCATION")"
        TMUX_POWERLINE_SEG_WEATHER_LAT=${lat_lon_arr[0]}
        TMUX_POWERLINE_SEG_WEATHER_LON=${lat_lon_arr[1]}
        if [[ -n "$TMUX_POWERLINE_SEG_WEATHER_LAT" && -n "$TMUX_POWERLINE_SEG_WEATHER_LON" ]]; then
            return 0
        fi
    fi

    tp_err_seg "Err: Could not detect location automatically"
    return 1
}
