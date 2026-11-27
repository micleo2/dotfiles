-----------------------
---- WINDOWS RULES ----
-----------------------

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

-- Assign apps to workspaces. Web apps and ssh windows are assigned in
-- dotfiles-private (common/hypr/window-rules.lua), next to their definitions.

-- communication 2
hl.window_rule({
	match = {
		class = "^(discord)$",
	},
	workspace = 2,
})

-- notes / research 3
hl.window_rule({
	match = {
		class = "^(md.obsidian.Obsidian)$",
	},
	workspace = 3,
})

-- 3D creative work 6
hl.window_rule({
	match = {
		class = "^(blender)$",
	},
	workspace = 6,
})
hl.window_rule({
	match = {
		class = "^(org.freecad.FreeCAD)$",
	},
	workspace = 6,
})
hl.window_rule({
	match = {
		class = "^(orca-slicer)$",
	},
	workspace = 6,
})
hl.window_rule({
	match = {
		class = "^(io.tangencylabs.solidcraft)$",
	},
	workspace = 6,
})
hl.window_rule({
	match = {
		title = "^(MakeraStudio)$",
	},
	workspace = 6,
})

-- 2D creative work 7
hl.window_rule({
	match = {
		class = "^(org.inkscape.Inkscape)$",
	},
	workspace = 7,
})
hl.window_rule({
	match = {
		title = "^(Adobe Photoshop 2024)$",
	},
	workspace = 7,
})
hl.window_rule({
	match = {
		class = "^(krita)$",
	},
	workspace = 7,
})

-- games 8
hl.window_rule({
	match = {
		class = "^(steam)$",
	},
	workspace = 8,
})
hl.window_rule({
	-- Only the real game window; dialogs float and stay readable
	match = {
		class = "steam_app_(.*)",
		float = false,
	},
	workspace = 8,
	fullscreen = true,
})
hl.window_rule({
	match = {
		class = "^(factorio)$",
	},
	workspace = 8,
	fullscreen = true,
})
hl.window_rule({
	match = {
		class = "^(com.moonlight_stream.Moonlight)$",
	},
	workspace = 8,
	fullscreen = true,
})

-- music/media 9
hl.window_rule({
	match = {
		class = "^(Spotify)$",
	},
	workspace = 9,
})

-- Floating kitty windows: anything launched through submap-builder's
-- kitty_float, or any kitty started with this title prefix.
hl.window_rule({
	name = "kitty-float",
	match = { title = "^kitty-float: .*" },
	float = true,
	center = true,
	size = "1200 680",
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

-------------------------
---- WORKSPACE RULES ----
-------------------------
hl.workspace_rule({ workspace = "2", layout = "monocle" })
hl.workspace_rule({ workspace = "6", layout = "monocle" })
hl.workspace_rule({ workspace = "7", layout = "monocle" })
hl.workspace_rule({ workspace = "8", layout = "monocle" })
hl.workspace_rule({ workspace = "4", layout = "scrolling" })
