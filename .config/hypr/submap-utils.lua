-- Utils map: tap SUPER+U to enter a submap for small utility floats.
--
-- btop and nvtop launch kitty with a `kitty-float-*` class; a window rule
-- (see window-workspace-rules.lua) floats + centers any window whose class
-- matches the `^kitty-float` prefix. The calculator is the shell's own
-- (quickshell/retro/calc/Calculator.qml), driven by qalc underneath.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	b = { label = "btop", exec_cmd = "kitty --class kitty-float-btop btop" },
	n = { label = "nvtop", exec_cmd = "kitty --class kitty-float-btop nvtop" },
	-- copy-path: pick a zoxide directory in the shell's launcher (the SUPER+Z
	-- list) and put it on the clipboard without a trailing newline.
	p = {
		label = "copy-path",
		exec_cmd = "bash -c 'target=$(zoxide query -l | retro-launcher -p copy) && wl-copy -n -- \"$target\"'",
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
	-- keymap: the shell's LCD view of the unicorne's layers
	-- (quickshell/retro/keymap), data from `make export` in ~/oss/keyboards.
	k = {
		label = "keymap",
		exec_cmd = "qs -c retro ipc call keymap toggle",
	},
}

submap_builder.define_submap("utils", "SUPER+U", submap_options_per_key)
