-- Power map: tap SUPER + P to enter a submap for managing power states.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	g = { label = "logout", exec_cmd = "uwsm stop" },
	k = { label = "lock", exec_cmd = "qs -c retro ipc call lock lock" },
	l = { label = "sleep", exec_cmd = "systemctl suspend" },
	r = { label = "reboot", exec_cmd = "systemctl reboot" },
	s = { label = "shutdown", exec_cmd = "systemctl poweroff" },
}

submap_builder.define_submap("power-menu", "SUPER+P", submap_options_per_key)
