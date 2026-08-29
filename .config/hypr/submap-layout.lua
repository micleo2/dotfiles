-- Layout map: tap SUPER+Y to change how the active workspace tiles.
--
-- Layouts are set by (re)registering a workspace rule for the active
-- workspace, which Hyprland applies and retiles immediately. The layout the
-- workspace is already using is left out of the overlay.
local submap_builder = require("submap-builder")

-- `direction` is a scrolling-layout option: "right" grows columns to the
-- right (scroll horizontally), "down" grows them downwards (scroll
-- vertically). hyprland.lua sets the global default to "right".
local HORIZONTAL = "right"
local VERTICAL = "down"

-- Hyprland exposes no way to read a workspace's current layout_opts back, so
-- the flipped directions are tracked here, per workspace, assuming the global
-- default until the key is first pressed.
local scroll_direction = {}

local function active_layout()
	local workspace = hl.get_active_workspace()
	return workspace and workspace.tiled_layout
end

local function unless_active(layout)
	return function()
		return active_layout() ~= layout
	end
end

local function set_layout(layout)
	return function()
		local workspace = hl.get_active_workspace()
		if not workspace then
			return
		end
		hl.workspace_rule({ workspace = workspace.name, layout = layout })
	end
end

-- Only the scrolling layout reads `direction`, so the option is listed in the
-- overlay only while the active workspace is scrolling. The key stays bound
-- either way: pressing it elsewhere records the direction on the workspace
-- rule, where it takes effect once that workspace becomes scrolling.
local function toggle_scroll_direction()
	local workspace = hl.get_active_workspace()
	if not workspace then
		return
	end

	local current = scroll_direction[workspace.name] or HORIZONTAL
	local flipped = current == HORIZONTAL and VERTICAL or HORIZONTAL

	scroll_direction[workspace.name] = flipped
	hl.workspace_rule({ workspace = workspace.name, layout_opts = { direction = flipped } })
end

local submap_options_per_key = {}
for key, layout in pairs({ m = "master", s = "scrolling", o = "monocle" }) do
	submap_options_per_key[key] = {
		label = layout,
		action = set_layout(layout),
		visible = unless_active(layout),
	}
end

submap_options_per_key.t = {
	label = "toggle-scroll-direction",
	action = toggle_scroll_direction,
	visible = function()
		return active_layout() == "scrolling"
	end,
}

submap_builder.define_submap("layout", "SUPER+Y", submap_options_per_key)
