-- Utils map: tap SUPER+U to enter a submap for small utility floats.
--
-- Both entries launch kitty with a `kitty-float-*` class; a single
-- window rule (see window-workspace-rules.lua) floats + centers any
-- window whose class matches the `^kitty-float` prefix.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	p = {
		label = "copy-path",
		-- `>/dev/null 2>&1`: wl-copy 2.3.0 daemonizes but only detaches
		-- stdin/stdout; stderr would keep the kitty pty open forever
		exec_cmd = "kitty --class kitty-float-z bash -c 'zoxide query -l | fzf | wl-copy -n >/dev/null 2>&1'",
	},
	-- qalc calculator: toggle the `calc` special workspace (scratchpad).
	c = {
		label = "calculator",
		exec_cmd = "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"calc\")'",
	},
}

submap_builder.define_submap("utils", "SUPER+U", submap_options_per_key)
