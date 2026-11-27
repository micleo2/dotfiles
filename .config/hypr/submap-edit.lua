-- Edit map: tap SUPER+E to enter a submap for opening frequently edited config files.
local submap_builder = require("submap-builder")
local private = require("private")

local submap_options_per_key = {
	a = { label = "apps.lua", action = submap_builder.float("kitty nvim " .. private.common_path("apps")) },
	h = { label = "hyprland.lua", action = submap_builder.float("kitty nvim ~/.config/hypr/hyprland.lua") },
}

submap_builder.define_submap("edit", "SUPER+E", submap_options_per_key)
