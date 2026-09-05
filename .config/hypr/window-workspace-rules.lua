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

-- Assign apps to workspaces.

-- communication 2
hl.window_rule({
	match = {
		class = "^(discord)$",
	},
	workspace = 2,
})
hl.window_rule({
	match = { class = ".*whatsapp.com.*" },
	workspace = 2,
})
hl.window_rule({
	match = { class = ".*messenger.com.*" },
	workspace = 2,
})
hl.window_rule({
	match = { class = ".*messages.google.com.*" },
	workspace = 2,
})

-- notes / research 3
hl.window_rule({
	match = {
		class = "^(md.obsidian.Obsidian)$",
	},
	workspace = 3,
})

-- utility apps 4
hl.window_rule({
	match = { class = ".*mail.google.com.*" },
	workspace = 4,
})
hl.window_rule({
	match = { title = ".*Home Assistant.*" },
	workspace = 4,
})
hl.window_rule({
	match = { class = ".*chrome-watch.*" },
	workspace = 4,
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
		class = "^(BambuStudio)$",
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

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "kitty-float-utils",
	-- class matching is RE2::FullMatch, so the pattern must consume the
	-- whole class string ("kitty-float-z").
	match = { class = "^kitty-float.*" },
	float = true,
	center = true,
	size = "1200 680",
})

-------------------------
---- WORKSPACE RULES ----
-------------------------
hl.workspace_rule({ workspace = "2", layout = "monocle" })
hl.workspace_rule({ workspace = "6", layout = "monocle" })
hl.workspace_rule({ workspace = "7", layout = "monocle" })
hl.workspace_rule({ workspace = "8", layout = "monocle" })
hl.workspace_rule({ workspace = "4", layout = "scrolling" })
