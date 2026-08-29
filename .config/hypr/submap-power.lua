-- Power map: tap SUPER + P to enter a submap for managing power states.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	d = { label = "shutdown", exec_cmd = "systemctl poweroff" },
	l = { label = "logout", exec_cmd = "uwsm stop" },
	r = { label = "reboot", exec_cmd = "systemctl reboot" },
	s = { label = "sleep", exec_cmd = "systemctl suspend" },
}

submap_builder.define_submap("power-menu", "SUPER+P", submap_options_per_key)
