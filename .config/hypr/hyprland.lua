local colors = require("colors")

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60",
	position = "0x0",
	scale = "1",
})

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal = "kitty"
local browser = "librewolf"
local music = "spicetify watch -s"
local runner = "rofi -show run"

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl --user start hyprpolkitagent")

	hl.exec_cmd("udiskie -a -n")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("swaync")
	hl.exec_cmd("hypridle")

	hl.exec_cmd("awww-daemon")

	hl.exec_cmd("waybar")
	hl.exec_cmd("fcitx5 -d")
	-- hl.exec_cmd("batsignal -b")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")

hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 8,
		gaps_out = 20,

		border_size = 1,

		col = {
			active_border = colors.alpha.primary["30"],
			inactive_border = "rgba(0,0,0,0)",
			-- inactive_border = colors.alpha.primary["10"],
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 10,
		rounding_power = 2,

		active_opacity = 0.8,
		inactive_opacity = 0.8,

		fullscreen_opacity = 0.8,
		dim_special = 0,

		shadow = {
			enabled = true,
			range = 25,
			render_power = 3,
			color = "rgba(00000055)",
		},

		blur = {
			enabled = true,
			special = false,
			popups = true,
			input_methods = true,
			ignore_opacity = true,
			xray = false,

			size = 6,
			passes = 3,
			contrast = 1.1,
			brightness = 0.85,
			vibrancy = 0.1696,
			noise = 0.05,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Bezier curves
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.38, 0.04 }, { 1, 0.07 } } })

-- Spring Curves
hl.curve("spring_menu", { type = "spring", mass = 1, stiffness = 80, dampening = 14 })
hl.curve("spring_window", { type = "spring", mass = 1, stiffness = 30, dampening = 8 })
hl.curve("spring_open", { type = "spring", mass = 1, stiffness = 30, dampening = 8 })
hl.curve("spring_workspace", { type = "spring", mass = 1.2, stiffness = 30, dampening = 10 })
hl.curve("spring_special", { type = "spring", mass = 1, stiffness = 30, dampening = 8 })

-- Window animations
hl.animation({ leaf = "windows", enabled = true, speed = 1, spring = "spring_window" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "spring_open", style = "popin 40%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "md3_accel", style = "popin 60%" })

-- Border animations (disabled)
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "borderangle", enabled = false })

-- Fade
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "md3_decel" })

-- Zoom cursor
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6, bezier = "md3_decel" })

-- Layer animations
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, spring = "spring_menu", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.6, bezier = "menu_accel", style = "slide" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.6, bezier = "menu_accel" })

-- Workspace animations
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "spring_workspace", style = "fade" })
hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 1,
	spring = "spring_special",
	style = "slidefadevert 40%",
})

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
		force_split = 2,
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
	},
})

---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		repeat_rate = 25,
		repeat_delay = 300,

		follow_mouse = 0,
		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local secondMod = "SUPER + SHIFT"

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(music))

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("$HOME/.config/rofi/launcher.sh"))
hl.bind(secondMod .. " + D", hl.dsp.exec_cmd(runner))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(
	secondMod .. " + Q",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

hl.bind(mainMod .. " + U", function()
	hl.timer(function()
		hl.dispatch(hl.dsp.dpms({ action = "toggle" }))
	end, { timeout = 500, type = "oneshot" })
end)

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("fcitx5-remote -t"))
hl.bind(mainMod .. " + DELETE", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("$HOME/.config/wlogout/logoutlaunch.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("$HOME/.config/hypr/script/wall-select.sh"))
hl.bind(secondMod .. " + W", hl.dsp.exec_cmd("$HOME/.config/hypr/script/change-color-scheme.sh"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("$HOME/.config/hypr/script/refresh.sh"))
hl.bind(secondMod .. " + R", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

hl.bind(mainMod .. " + O", hl.dsp.window.set_prop({ window = "active", prop = "opaque", value = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + G", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(secondMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m active -m output -o $HOME/Screenshots"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window -o $HOME/Screenshots"))
hl.bind(secondMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region -o $HOME/Screenshots"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move with secondMod + arrow keys
hl.bind(secondMod .. " + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(secondMod .. " + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(secondMod .. " + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(secondMod .. " + J", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + TAB", function()
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with secondMod + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(secondMod .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(secondMod .. " + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind(secondMod .. " + M", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer Rules
hl.layer_rule({
	name = "awww",
	match = { namespace = "awww-daemon" },
	no_anim = true,
})

hl.layer_rule({
	name = "mpvpaper",
	match = { namespace = "mpvpaper" },
	no_anim = true,
})

hl.layer_rule({
	name = "rofi-blur",
	match = { namespace = "rofi" },
	blur = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "waybar-blur",
	match = { namespace = "waybar" },
	blur = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "notifications",
	match = { namespace = "swaync-notification-window" },
	blur = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "wlogout",
	match = { namespace = "wlogout" },
	blur = true,
	animation = "fade",
})

hl.layer_rule({
	name = "wlogout_dialog",
	match = { namespace = "logout_dialog" },
	blur = true,
	animation = "fade",
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})
