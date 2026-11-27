-- Edit map: tap SUPER+E to enter a submap for opening frequently edited config files.
local submap_builder = require("submap-builder")
local private = require("private")

local submap_options_per_key = {
	a = { label = "apps.lua", exec_cmd = submap_builder.kitty_float("apps.lua", "nvim " .. private.common_path("apps")) },
	h = { label = "hyprland.lua", exec_cmd = submap_builder.kitty_float("hyprland.lua", "nvim ~/.config/hypr/hyprland.lua") },
}

submap_builder.define_submap("edit", "SUPER+E", submap_options_per_key)
