#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# CONSTANTS
# =========================================================
readonly WALL_DIR="$HOME/Downloads/wallpapers"
readonly CACHE_DIR="$HOME/.cache/wallcache"
readonly SCRIPTS_DIR="$HOME/.config/hypr/script"
readonly ROFI_THEME="$HOME/.config/rofi/applets/wallSelect.rasi"
readonly ROFI_COLOR_PICKER_THEME="$HOME/.config/rofi/applets/colorPicker.rasi"
readonly ROFI_IMAGES_DIR="$HOME/.config/rofi/images" # THÊM DÒNG NÀY
readonly FALLBACK_ICON="$HOME/.config/rofi/images/fallback.png"
readonly TEMP_FRAME="/tmp/matugen-frame.png"
readonly CURRENT_COLOR_INDEX="$HOME/.cache/matugen_color_index"

readonly VIDEO_EXTENSIONS="mp4|webm|mov|gif"

readonly THUMB_WIDTH=800
readonly THUMB_HEIGHT=450
readonly THUMB_CROP="${THUMB_WIDTH}x${THUMB_HEIGHT}"
readonly THUMB_ROUNDED=24

readonly AWWW_FPS=60
readonly AWWW_TYPE="fade"
readonly AWWW_DURATION=1

# =========================================================
# INITIALIZATION
# =========================================================

init_directories() {
	mkdir -p "$CACHE_DIR"
	mkdir -p "$ROFI_IMAGES_DIR"

	touch "$CURRENT_COLOR_INDEX"
}

get_focused_monitor() {
	hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
}

get_optimal_jobs() {
	local cores
	cores=$(nproc)

	if [[ $cores -le 2 ]]; then
		echo 2
	elif [[ $cores -gt 4 ]]; then
		echo 4
	else
		echo $((cores - 1))
	fi
}

# =========================================================
# THUMBNAIL GENERATION
# =========================================================

get_file_hash() {
	local file="$1"
	stat -c '%s-%Y' "$file"
}

generate_image_thumbnail() {
	local input="$1"
	local output="$2"

	magick "$input" \
		-resize "${THUMB_CROP}^" \
		-gravity center \
		-extent "$THUMB_CROP" \
		\( -size "${THUMB_CROP}" xc:none \
		-draw "roundrectangle 0,0 ${THUMB_WIDTH},${THUMB_HEIGHT} ${THUMB_ROUNDED},${THUMB_ROUNDED}" \) \
		-alpha set \
		-compose DstIn \
		-composite \
		"$output"
}

generate_video_thumbnail() {
	local input="$1"
	local output="$2"

	ffmpeg -y \
		-ss 00:00:02 \
		-i "$input" \
		-vframes 1 \
		-vf "scale=${THUMB_WIDTH}:${THUMB_HEIGHT}:force_original_aspect_ratio=increase,crop=${THUMB_WIDTH}:${THUMB_HEIGHT}" \
		"$output" \
		-loglevel quiet
}

process_media() {
	echo 'Run process_media ...'
	local media="$1"
	local filename
	filename=$(basename "$media")

	local base_name="${filename%.*}"
	local ext="${filename##*.}"

	local cache_file="${CACHE_DIR}/${base_name}.png"
	local hash_file="${CACHE_DIR}/.${base_name}.hash"
	local lock_file="${CACHE_DIR}/.lock_${base_name}"

	local current_hash
	current_hash=$(get_file_hash "$media")

	(
		flock -x 200

		if [[ ! -f "$cache_file" ]] ||
			[[ ! -f "$hash_file" ]] ||
			[[ "$current_hash" != "$(cat "$hash_file" 2>/dev/null)" ]]; then

			if [[ "${ext,,}" =~ ^($VIDEO_EXTENSIONS)$ ]]; then
				generate_video_thumbnail "$media" "$cache_file"
			else
				generate_image_thumbnail "$media" "$cache_file"
			fi

			echo "$current_hash" >"$hash_file"
		fi

	) 200>"$lock_file"
}

export -f process_media get_file_hash generate_image_thumbnail generate_video_thumbnail
export CACHE_DIR THUMB_WIDTH THUMB_HEIGHT THUMB_ROUNDED THUMB_CROP

# =========================================================
# CACHE MANAGEMENT
# =========================================================

cleanup_old_locks() {
	rm -f "${CACHE_DIR}"/.lock_* 2>/dev/null || true
}

generate_thumbnails_background() {
	echo "Generating thumbnails in background..." >&2

	local jobs
	jobs=$(get_optimal_jobs)

	# Chạy background process với xargs parallel
	find "$WALL_DIR" -type f \( \
		-iname "*.jpg" -o \
		-iname "*.jpeg" -o \
		-iname "*.png" -o \
		-iname "*.webp" -o \
		-iname "*.gif" -o \
		-iname "*.mp4" -o \
		-iname "*.webm" -o \
		-iname "*.mov" \
		\) -print0 |
		xargs -0 -P "$jobs" -I {} bash -c 'export VIDEO_EXTENSIONS="'"$VIDEO_EXTENSIONS"'"; process_media "{}"'
}

cleanup_orphan_cache() {
	(
		for cached in "$CACHE_DIR"/*.png; do
			[[ -f "$cached" ]] || continue

			local base
			base=$(basename "${cached%.png}")

			if ! find "$WALL_DIR" -type f -iname "$base.*" | grep -q .; then
				rm -f "$cached" \
					"${CACHE_DIR}/.${base}.hash" \
					"${CACHE_DIR}/.lock_${base}"
			fi
		done

		cleanup_old_locks
	) &
}

kill_old_rofi() {
	if pidof rofi >/dev/null; then
		pkill rofi
		sleep 0.1
	fi
}

# =========================================================
# ROFI MENU - CHỌN WALLPAPER
# =========================================================

build_rofi_menu() {
	find "$WALL_DIR" -type f \
		\( \
		-iname "*.jpg" -o \
		-iname "*.jpeg" -o \
		-iname "*.png" -o \
		-iname "*.webp" -o \
		-iname "*.gif" -o \
		-iname "*.mp4" -o \
		-iname "*.webm" -o \
		-iname "*.mov" \
		\) -print0 |
		xargs -0 basename -a |
		LC_ALL=C sort -V |
		while IFS= read -r file; do
			local thumb="${CACHE_DIR}/${file%.*}.png"
			[[ ! -f "$thumb" ]] && thumb="$FALLBACK_ICON"

			printf '%s\x00icon\x1f%s\n' "$file" "$thumb"
		done
}

show_rofi_menu() {
	build_rofi_menu | rofi -i -show -dmenu -theme "$ROFI_THEME"
}

# =========================================================
# MATUGEN COLOR PICKER
# =========================================================

is_video_file() {
	local file="$1"
	local ext="${file##*.}"
	[[ "${ext,,}" =~ ^($VIDEO_EXTENSIONS)$ ]]
}

extract_frame_from_video() {
	local video="$1"
	local output="$2"

	ffmpeg -y \
		-i "$video" \
		-frames:v 1 \
		"$output" \
		-loglevel quiet
}

get_matugen_input() {
	local wallpaper="$1"

	if is_video_file "$wallpaper"; then
		extract_frame_from_video "$wallpaper" "$TEMP_FRAME"
		echo "$TEMP_FRAME"
	else
		echo "$wallpaper"
	fi
}

get_colors_from_matugen() {
	local image="$1"
	local mode="${2:-dark}"
	local max_colors=4

	matugen image "$image" \
		-m "$mode" \
		--show-source-colors 2>/dev/null |
		head -n "$max_colors"
}

show_color_picker() {
	local -n colors_ref="$1"
	local menu=""
	local index

	for i in "${!colors_ref[@]}"; do
		local color="${colors_ref[$i]}"
		menu+="$i  <span foreground='${color}'></span> ${color}"$'\n'
	done

	index=$(printf "%b" "$menu" |
		rofi \
			-dmenu \
			-i \
			-markup-rows \
			-format i \
			-no-custom \
			-p "Select color scheme" \
			-theme "$ROFI_COLOR_PICKER_THEME" 2>/dev/null)

	if [[ ! "$index" =~ ^[0-9]+$ ]]; then
		index=0
	fi

	((index < 0)) && index=0
	((index > 3)) && index=3

	echo "$index"
}

# =========================================================
# SET WALLPAPER (awww/mpvpaper)
# =========================================================

start_awww_daemon() {
	pgrep awww-daemon >/dev/null || awww-daemon --format xrgb
}

kill_mpvpaper() {
	pkill mpvpaper 2>/dev/null || true
}

set_image_wallpaper() {
	local monitor="$1"
	local image="$2"

	kill_mpvpaper

	awww img \
		-o "$monitor" \
		"$image" \
		--transition-fps "$AWWW_FPS" \
		--transition-type "$AWWW_TYPE" \
		--transition-duration "$AWWW_DURATION"
}

set_video_wallpaper() {
	local monitor="$1"
	local video="$2"

	kill_mpvpaper
	awww clear

	mpvpaper \
		-o "loop \
        no-audio \
        hwdec=auto-copy-safe \
        profile=fast \
        interpolation=no \
        video-sync=display-desync \
        scale=bilinear \
        cscale=no \
        deband=no" \
		"$monitor" \
		"$video" &
}

set_wallpaper() {
	local wallpaper="$1"
	local monitor="$2"
	local ext="${wallpaper##*.}"

	start_awww_daemon

	if [[ "${ext,,}" =~ $VIDEO_EXTENSIONS ]]; then
		set_video_wallpaper "$monitor" "$wallpaper"
	else
		set_image_wallpaper "$monitor" "$wallpaper"
	fi
}

# =========================================================
# CREATE ROFI IMAGES (THÊM FUNCTION NÀY)
# =========================================================

create_rofi_images() {
	local input="$1"
	local temp_thumb="${ROFI_IMAGES_DIR}/currentWal.thumb"
	local temp_sqre="${ROFI_IMAGES_DIR}/currentWal.sqre"
	local temp_quad="${ROFI_IMAGES_DIR}/currentWalQuad.quad"

	log_info "Creating rofi images..."

	# Create blurred thumbnail
	magick "$input" \
		-strip \
		-resize 1000 \
		-gravity center \
		-extent 1000 \
		-blur "30x30" \
		-quality 90 \
		"${ROFI_IMAGES_DIR}/currentWalBlur.thumb"

	# Create standard thumbnail
	magick "$input" \
		-strip \
		-resize 1000 \
		-gravity center \
		-extent 1000 \
		-quality 90 \
		"$temp_thumb"

	# Create square thumbnail
	magick "$input" \
		-strip \
		-thumbnail 500x500^ \
		-gravity center \
		-extent 500x500 \
		"$temp_sqre"

	# Create quad image (cắt góc)
	magick "$temp_sqre" \
		\( -size 500x500 xc:white \
		-fill "rgba(0,0,0,0.7)" \
		-draw "polygon 400,500 500,500 500,0 450,0" \
		-fill black \
		-draw "polygon 500,500 500,0 450,500" \
		\) \
		-alpha Off \
		-compose CopyOpacity \
		-composite \
		"$temp_quad"

	mv "$temp_quad" "${ROFI_IMAGES_DIR}/currentWalQuad.png"

}

# =========================================================
# APPLY MATUGEN THEME
# =========================================================

apply_matugen_theme() {
	local image="$1"
	local mode="$2"
	local color_index="$3"

	log_info "Applying matugen theme with color index: $color_index"

	matugen image "$image" \
		-m "$mode" \
		--source-color-index "$color_index" >/dev/null 2>&1
}

# =========================================================
# POST THEME TASKS
# =========================================================

create_hover_icons() {
	if [[ -f "$SCRIPTS_DIR/create-png-hover-icon.sh" ]]; then
		"$SCRIPTS_DIR/create-png-hover-icon.sh"
	fi
}

save_current_wallpaper() {
	local wallpaper="$1"
	echo "$wallpaper" >~/.cache/current_wallpaper
}

save_current_color_index() {
	local index="$1"
	echo "$index" >"$CURRENT_COLOR_INDEX"
}

send_notification() {
	local wallpaper="$1"
	notify-send -e \
		-h string:x-canonical-private-synchronous:wall_select \
		"Wallpaper" \
		"Wallpaper changed and theme applied" \
		-i "$wallpaper"
}

cleanup_gtk_css() {
	local gtk_dir="$HOME/.config/gtk-4.0"

	rm -f \
		"$gtk_dir/gtk.css" \
		"$gtk_dir/gtk-dark.css" \
		2>/dev/null || true

	log_info "Removed old GTK CSS files (if existed)"
}

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

# =========================================================
# MAIN
# =========================================================

main() {
	# Khởi tạo
	init_directories
	cleanup_old_locks

	# Background tasks
	generate_thumbnails_background
	cleanup_orphan_cache

	# Kill rofi cũ
	kill_old_rofi

	# BƯỚC 1: Chọn wallpaper từ rofi
	local selection
	selection=$(show_rofi_menu)

	[[ -z "${selection:-}" ]] && exit 0

	local selected="${WALL_DIR}/${selection}"
	log_info "Selected wallpaper: $(basename "$selected")"

	# BƯỚC 2: Chạy matugen để lấy màu
	log_info "Extracting colors from matugen..."

	local matugen_input
	matugen_input=$(get_matugen_input "$selected")

	# Lưu wallpaper path
	save_current_wallpaper "$matugen_input"

	local colors
	mapfile -t colors < <(get_colors_from_matugen "$matugen_input" "dark")

	if [[ ${#colors[@]} -eq 0 ]]; then
		log_error "No colors found from matugen"
		exit 1
	fi

	# BƯỚC 3: Rofi color picker
	log_info "Showing color picker..."
	local selected_index
	selected_index=$(show_color_picker colors)

	save_current_color_index "$selected_index"

	log_info "Selected color index: $selected_index"

	# BƯỚC 4: Set wallpaper BẰNG AWWW/MPVPAPER
	log_info "Setting wallpaper with awwww/mpvpaper..."
	local monitor
	monitor=$(get_focused_monitor)
	set_wallpaper "$selected" "$monitor"

	# Đợi wallpaper load xong
	sleep 0.5

	# BƯỚC 5: Apply matugen theme với color index đã chọn
	cleanup_gtk_css

	log_info "Applying matugen theme..."
	apply_matugen_theme "$matugen_input" "dark" "$selected_index"

	gsettings set org.gnome.desktop.interface gtk-theme ""
	gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3

	# BƯỚC 6: Tạo rofi images từ wallpaper (THÊM DÒNG NÀY)
	log_info "Creating rofi images..."
	create_rofi_images "$matugen_input"

	# BƯỚC 7: Tạo hover icons cho wlogout
	log_info "Creating hover icons for wlogout..."

	# BƯỚC 8: Thông báo hoàn tất
	send_notification "$matugen_input"

	sleep 1

	log_info "Restarting xdg-desktop-portal..."

	killall xdg-desktop-portal-gtk 2>/dev/null || true
	killall xdg-desktop-portal 2>/dev/null || true

	log_success "Wallpaper changed and theme applied successfully!"

	create_hover_icons

}

main "$@"
