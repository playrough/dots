#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# CONFIG
# =========================================================

readonly CURRENT_COLOR_INDEX="$HOME/.cache/matugen_color_index"
readonly CURRENT_WALL="$HOME/.cache/current_wallpaper"
readonly ROFI_THEME="$HOME/.config/rofi/applets/colorPicker.rasi"

readonly SCHEMES=(
	"scheme-tonal-spot"
	"scheme-content"
	"scheme-expressive"
	"scheme-fidelity"
	"scheme-fruit-salad"
	"scheme-monochrome"
	"scheme-neutral"
	"scheme-rainbow"
	"scheme-vibrant"
)

# =========================================================
# LOGGING
# =========================================================

log_info() {
	echo "INFO: $*"
}

log_error() {
	echo "ERROR: $*" >&2
}

log_success() {
	echo "SUCCESS: $*"
}

send_notification() {
	local scheme="$1"

	notify-send -e \
		-h string:x-canonical-private-synchronous:change-color-scheme \
		"Scheme" \
		"Scheme changed: ${scheme#scheme-}"
}

# =========================================================
# ROFI MENU
# =========================================================

show_scheme_picker() {
	local menu=""
	local scheme
	local display

	declare -A MAP

	for scheme in "${SCHEMES[@]}"; do

		display="${scheme//scheme-/}"
		display="${display//-/ }"

		case "$scheme" in
		scheme-tonal-spot)
			icon="<span foreground='#89b4fa'></span>"
			;; # blue (primary)
		scheme-content)
			icon="<span foreground='#a6e3a1'>󰋩</span>"
			;; # green (content)
		scheme-expressive)
			icon="<span foreground='#cba6f7'></span>"
			;; # purple (creative)
		scheme-fidelity)
			icon="<span foreground='#94e2d5'></span>"
			;; # cyan (tech)
		scheme-fruit-salad)
			icon="<span foreground='#fab387'>󱁇</span>"
			;; # orange (warm)
		scheme-monochrome)
			icon="<span foreground='#313244'></span>"
			;; # soft gray
		scheme-neutral)
			icon="<span foreground='#bac2de'></span>"
			;; # neutral gray
		scheme-rainbow)
			icon="<span foreground='#f9e2af'>󱝂</span>"
			;; # yellow (highlight)
		scheme-vibrant)
			icon="<span foreground='#f38ba8'></span>"
			;; # pink (accent)
		esac

		label="$icon $display"

		MAP["$label"]="$scheme"
		menu+="$label"$'\n'
	done

	selected=$(printf "%s" "$menu" |
		rofi -dmenu -markup-rows -i -p "Select matugen scheme" -theme "$ROFI_THEME")

	echo "${MAP[$selected]}"
}

# =========================================================
# MAIN
# =========================================================

main() {

	if [[ ! -f "$CURRENT_WALL" ]]; then
		log_error "Current wallpaper cache not found"
		exit 1
	fi

	local wallpaper
	wallpaper=$(<"$CURRENT_WALL")

	if [[ ! -f "$wallpaper" ]]; then
		log_error "Wallpaper not found: $wallpaper"
		exit 1
	fi

	local color_index=0

	if [[ -f "$CURRENT_COLOR_INDEX" ]]; then
		color_index=$(<"$CURRENT_COLOR_INDEX")
	fi

	log_info "Wallpaper: $(basename "$wallpaper")"
	log_info "Color index: $color_index"

	local selected
	selected=$(show_scheme_picker)

	[[ -z "${selected:-}" ]] && exit 0

	local scheme
	scheme=$(awk '{print $1}' <<<"$selected")

	log_info "Applying scheme: $scheme"

	matugen image "$wallpaper" \
		-t "$scheme" \
		--source-color-index "$color_index" \
		>/dev/null 2>&1

	log_success "Matugen scheme changed successfully!"

	send_notification "$scheme"

	sleep 1

	log_info "Restarting xdg-desktop-portal..."

	killall xdg-desktop-portal-gtk 2>/dev/null || true
	killall xdg-desktop-portal 2>/dev/null || true
}

main "$@"
