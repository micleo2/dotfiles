-- Hyprland config, split across the files required at the bottom of each
-- section. Wiki: https://wiki.hypr.land/Configuring/Start/

-------------------
---- AUTOSTART ----
-------------------

-- Runs once per session (not on reload).
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"kitty +kitten panel -o clear_all_mouse_actions=no -o default_pointer_shape=arrow -o pointer_shape_when_dragging=arrow -o font_size=20 --edge=background ~/dotfiles/scripts/hypr/ttfx-background.sh"
	)
	-- hl.exec_cmd("hyprpaper")
	hl.exec_cmd("QT_FONT_DPI= qs -c retro")
	hl.exec_cmd("QT_FONT_DPI= qs -c gw-idle")
	hl.exec_cmd("hyprpm reload")
	hl.exec_cmd("swaync")
	hl.exec_cmd("snappy-switcher --daemon")
	hl.exec_cmd("udiskie -a -n")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("kitty --class kitty-float-calc qalc")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},
		resize_on_border = false, -- enable resizing windows by dragging on borders
		allow_tearing = false,
		layout = "master",
	},

	decoration = {
		inactive_opacity = 0.9,
		blur = {
			enabled = false,
		},
		rounding = 10,
		rounding_power = 2,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "quick" })
hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = false })

-- "Smart gaps"
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
	name = "no-gaps-wtv1",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})
hl.window_rule({
	name = "no-gaps-f1",
	match = { float = false, workspace = "f[1]" },
	border_size = 0,
	rounding = 0,
})

-- Skip the fade-out snapshot for the QS submap overlay so it vanishes
-- instantly when the submap resets (no_anim -> no snapshot in onUnmap).
-- Lets screenshot/record captures with a short delay beat the unmap.
hl.layer_rule({
	name = "no-anim-qs-submap",
	match = { namespace = "qs-submap-overlay" },
	no_anim = true,
})

hl.config({
	dwindle = {
		preserve_split = true,
	},
	master = {
		new_status = "slave",
	},
	scrolling = {
		fullscreen_on_one_column = true,
		direction = "right",
		wrap_focus = true,
	},
})

----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true,
	},
})

hl.config({
	ecosystem = {
		no_donation_nag = true,
	},
})
-------------
-- INPUT ----
-------------

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

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

---------------------
---- KEYBINDINGS ----
---------------------
local function M(key)
	return "SUPER + " .. key
end
local function S(key)
	return "SHIFT + " .. key
end
local function C(key)
	return "CTRL + " .. key
end

-- One-key app launcher submap (SUPER + A) + web app window rules
require("submap-apps")
require("submap-power")
require("submap-screenshots")
require("submap-utils")
require("submap-layout")
require("submap-edit")
require("submap-topbar")
-- SUPER + ? lists the submaps above with their activation keys. Must come
-- after the requires so every submap is registered.
require("submap-builder").generate_helper_submap()

-- Window binds
hl.bind(M("Q"), hl.dsp.window.close())
hl.bind(M(S("Q")), hl.dsp.window.kill())
hl.bind(M("F"), hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(M(S("F")), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
-- Make the window believe it's fullscreen but it's not.
hl.bind(M(C("F")), hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))

-- Move/resize windows
hl.bind(M("G"), hl.dsp.window.drag(), { mouse = true })
hl.bind(M(S("G")), hl.dsp.window.resize(), { mouse = true })

-- Apps on hotkeys
hl.bind(M("Space"), hl.dsp.exec_cmd("rofi -show drun -show-icons"))
hl.bind(M("S"), hl.dsp.exec_cmd("kitty"))

-- Alt+Tab: standard MRU switching
hl.bind("ALT + Tab", hl.dsp.exec_cmd("snappy-switcher next --mod alt"), { description = "Snappy Switcher" })

-- open kitty in a directory. directory options are generated by zoxide
hl.bind(
	M("Z"),
	hl.dsp.exec_cmd(
		'bash -c \'target=$(zoxide query -l | rofi -dmenu); [ -n "$target" ] && kitty --directory "$target" fish\''
	)
)

-- Browser menu
hl.bind(M("B"), hl.dsp.exec_cmd("~/dotfiles/scripts/menus/browser-menu.sh"))

-- Toggle top bar (SUPER+T is the top bar submap, see submap-topbar.lua)
hl.bind(M(S("T")), hl.dsp.exec_cmd("qs -c retro ipc call topbar toggle"))

for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	-- Switch workspaces with mainMod + [0-9]
	hl.bind(M(key), hl.dsp.focus({ workspace = i }))
	-- Move active window to a workspace with mainMod + SHIFT + [0-9]
	hl.bind(M(S(key)), hl.dsp.window.move({ workspace = i }))
end

-- Toggle between last focused workspace
hl.bind(M("d"), hl.dsp.focus({ workspace = "previous" }))
hl.bind(M(S("d")), hl.dsp.focus({ urgent_or_last = true }))
hl.bind(M("Tab"), hl.dsp.focus({ last = true }))

-- Layout-aware hjkl
local layoutAwareBinds = {
	h = {
		master = hl.dsp.focus({ direction = "left" }),
		scrolling = hl.dsp.layout("focus left"),
		monocle = hl.dsp.layout("cycleprev"),
	},
	j = { master = hl.dsp.focus({ direction = "down" }), scrolling = hl.dsp.layout("focus down") },
	k = { master = hl.dsp.focus({ direction = "up" }), scrolling = hl.dsp.layout("focus up") },
	l = {
		master = hl.dsp.focus({ direction = "right" }),
		scrolling = hl.dsp.layout("focus right"),
		monocle = hl.dsp.layout("cyclenext"),
	},
}
for key, actions in pairs(layoutAwareBinds) do
	hl.bind(M(key), function()
		local currentLayout = hl.get_active_workspace().tiled_layout
		local targetAction = actions[currentLayout]
		if targetAction then
			hl.dispatch(targetAction)
		else
			-- default fall back
			hl.dispatch(actions.master)
		end
	end)
end

-- Move window with M+arrows
hl.bind(M("left"), hl.dsp.window.move({ direction = "left" }))
hl.bind(M("down"), hl.dsp.window.move({ direction = "down" }))
hl.bind(M("up"), hl.dsp.window.move({ direction = "up" }))
hl.bind(M("right"), hl.dsp.window.move({ direction = "right" }))

hl.bind(M(S("left")), hl.dsp.layout("swapcol l"))
hl.bind(M(S("right")), hl.dsp.layout("swapcol r"))

-- clipboard
require("universal-clipboard")
hl.bind(
	M(S("V")),
	hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy && wl-paste")
)

-- dictation
hl.bind(M("R"), hl.dsp.exec_cmd("voxtype record start"))
hl.bind(M("R"), hl.dsp.exec_cmd("voxtype record stop"), { release = true })

-- Laptop multimedia keys for volume and LCD brightness.
-- Volume goes through the shell (taskbar/VolumeWidget.qml) rather than
-- straight to wpctl so the OSD flashes and the step matches the chip.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs -c retro ipc call volume up"), { locked = true, repeating = true })
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("qs -c retro ipc call volume down"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("qs -c retro ipc call volume mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Brightness
-- Routed through the shell rather than straight to brightnessctl so that one
-- place decides the backend (ddcutil on a DDC monitor, the panel backlight
-- otherwise) and so the OSD reflects every change.
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("qs -c retro ipc call brightness up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("qs -c retro ipc call brightness down"),
	{ locked = true, repeating = true }
)

require("window-workspace-rules")

-------------------
----- DISPLAY -----
-------------------
require("monitors")
hl.env("QT_FONT_DPI", "192")
-- Unscale XWayland to fix blurry applications
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
