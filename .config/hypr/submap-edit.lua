-- Edit map: tap SUPER+E to enter a submap for opening frequently edited config files.
--
-- Each entry launches kitty with a `kitty-float-*` class; the shared
-- `kitty-float-utils` window rule (see window-workspace-rules.lua) floats,
-- centers, and sizes any window whose class matches the `^kitty-float` prefix.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	h = { label = "hyprland.lua", exec_cmd = "kitty --class kitty-float-edit nvim ~/.config/hypr/hyprland.lua" },
	m = { label = "monitors.lua", exec_cmd = "kitty --class kitty-float-edit nvim ~/.config/hypr/monitors.lua" },
}

submap_builder.define_submap("edit", "SUPER+E", submap_options_per_key)