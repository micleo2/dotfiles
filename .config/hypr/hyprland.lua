-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal = "kitty"
local fileManager = "nautilus"

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	hl.exec_cmd("QT_FONT_DPI= qs -c retro & hyprpaper &")
	hl.exec_cmd("hyprpm reload")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("swaync")
	hl.exec_cmd("snappy-switcher --daemon")
	hl.exec_cmd("udiskie -a -n")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

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

hl.workspace_rule({ workspace = "4", layout = "scrolling" })
hl.workspace_rule({ workspace = "6", layout = "monocle" })
hl.workspace_rule({ workspace = "9", layout = "scrolling" })
hl.workspace_rule({ workspace = "9", layout_opts = { direction = "right" } })

----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(
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
local mainMod = "SUPER"
local function M(key)
	return "SUPER + " .. key
end
local function S(key)
	return "SHIFT + " .. key
end
local function C(key)
	return "CTRL + " .. key
end

-- Window binds
hl.bind(M("Q"), hl.dsp.window.close())
hl.bind(M(S("Q")), hl.dsp.window.kill())
hl.bind(M("F"), hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(M(S("F")), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
-- Make the window believe it's fullscreen but it's not.
hl.bind(M(C("F")), hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Apps on hotkeys
hl.bind(M("Space"), hl.dsp.exec_cmd("rofi -show drun -show-icons"))
hl.bind(M("S"), hl.dsp.exec_cmd(terminal))
hl.bind(M("E"), hl.dsp.exec_cmd(fileManager))
hl.bind(M("Y"), hl.dsp.exec_cmd("kitty yazi"))

-- Alt+Tab: standard MRU switching
hl.bind("ALT + Tab", hl.dsp.exec_cmd("snappy-switcher next --mod alt"), { description = "Snappy Switcher" })

-- Super+Tab: workspace-filtered switching
hl.bind(
	"SUPER + TAB",
	hl.dsp.exec_cmd("snappy-switcher next --workspace --mod super"),
	{ description = "Snappy Switcher (Workspace)" }
)

-- open kitty in a directory. directory options are generated by zoxide
hl.bind(
	M("Z"),
	hl.dsp.exec_cmd(
		'bash -c \'target=$(zoxide query -l | rofi -dmenu); [ -n "$target" ] && kitty --directory "$target" fish\''
	)
)

-- Power menu
hl.bind(M("P"), hl.dsp.exec_cmd("~/dotfiles/scripts/menus/power-menu.sh"))

-- Browser menu
hl.bind(M("B"), hl.dsp.exec_cmd("~/dotfiles/scripts/menus/browser-menu.sh"))

-- Toggle top bar
hl.bind(M("T"), hl.dsp.exec_cmd("qs -c retro ipc call topbar toggle"))

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

-- hyprwhspr
hl.bind(M("V"), hl.dsp.exec_cmd('echo "start" > "$XDG_RUNTIME_DIR/hyprwhspr/recording_control"'))
hl.bind(M("V"), hl.dsp.exec_cmd('echo "stop" > "$XDG_RUNTIME_DIR/hyprwhspr/recording_control"'), { release = true })

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
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Brightness
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

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
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

-- Assign apps to workspaces.
hl.window_rule({
	match = {
		class = "^(steam)$",
	},
	workspace = 6,
})
hl.window_rule({
	match = {
		class = "steam_app_(.*)",
	},
	workspace = 7,
	fullscreen = true,
})
hl.window_rule({
	match = {
		class = "^(factorio)$",
	},
	workspace = 6,
	fullscreen = true,
})
hl.window_rule({
	match = {
		class = "^(discord)$",
	},
	workspace = 9,
})
hl.window_rule({
	match = {
		class = "^(Spotify)$",
	},
	workspace = 9,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

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
