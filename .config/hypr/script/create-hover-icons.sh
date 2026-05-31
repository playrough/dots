#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# CONFIGURATION
# =========================================================
readonly MATUGEN_LUA="$HOME/.config/hypr/colors.lua"
readonly ICON_DIR="$HOME/.config/wlogout/icons"
readonly COLORIZE_PERCENT=95

# =========================================================
# FUNCTIONS
# =========================================================

log_error() {
	echo "ERROR: $*" >&2
}

log_info() {
	echo "INFO: $*"
}

log_success() {
	echo "SUCCESS: $*"
}

get_surface_color_from_lua() {
	local color

	if [[ ! -f "$MATUGEN_LUA" ]]; then
		log_error "Matugen colors.lua not found at: $MATUGEN_LUA"
		return 1
	fi

	color=$(lua -e "local c = dofile('$MATUGEN_LUA'); print(c.surface)" 2>/dev/null)

	if [[ -z "$color" ]]; then
		log_error "Surface color not found in $MATUGEN_LUA"
		return 1
	fi

	echo "$color"
}

create_hover_icon() {
	local original="$1"
	local hover="${original%.png}-hover.png"

	log_info "Creating: $(basename "$hover")"

	magick "$original" \
		-alpha on \
		-fill "$HOVER_COLOR" \
		-colorize "$COLORIZE_PERCENT%" \
		"$hover"
}

# =========================================================
# MAIN
# =========================================================

main() {
	HOVER_COLOR=$(get_surface_color_from_lua) || exit 1
	log_info "Hover color: $HOVER_COLOR"

	# Validate icon directory
	if [[ ! -d "$ICON_DIR" ]]; then
		log_error "Icon directory not found: $ICON_DIR"
		exit 1
	fi

	# Process each PNG file
	local count=0
	for file in "$ICON_DIR"/*.png; do
		[[ -f "$file" ]] || continue
		[[ "$file" == *-hover.png ]] && continue

		create_hover_icon "$file"
		((count++))
	done

	log_success "Created $count hover icons for wlogout"
}

main "$@"
