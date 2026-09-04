-- Utils map: tap SUPER+U to enter a submap for small utility floats.
--
-- copy-path launches kitty with a `kitty-float-*` class; a window rule
-- (see window-workspace-rules.lua) floats + centers any window whose class
-- matches the `^kitty-float` prefix. The calculator is the shell's own
-- (quickshell/retro/calc/Calculator.qml), driven by qalc underneath.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	b = { label = "btop", exec_cmd = "kitty --class kitty-float-btop btop" },
	n = { label = "nvtop", exec_cmd = "kitty --class kitty-float-btop nvtop" },
	p = {
		label = "copy-path",
		-- `>/dev/null 2>&1`: wl-copy 2.3.0 daemonizes but only detaches
		-- stdin/stdout; stderr would keep the kitty pty open forever
		exec_cmd = "kitty --class kitty-float-z bash -c 'zoxide query -l | fzf | wl-copy -n >/dev/null 2>&1'",
	},
	-- qalc: the shell's LCD calculator, on the focused monitor.
	c = {
		label = "calculator",
		exec_cmd = "qs -c retro ipc call calc toggle",
	},
	s = {
		label = "ssh",
		exec_cmd = "retro-ssh",
	},
}

submap_builder.define_submap("utils", "SUPER+U", submap_options_per_key)
