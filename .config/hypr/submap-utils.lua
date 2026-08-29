-- Utils map: tap SUPER+U to enter a submap for small utility floats.
--
-- Both entries launch kitty with a `kitty-float-*` class; a single
-- window rule (see window-workspace-rules.lua) floats + centers any
-- window whose class matches the `^kitty-float` prefix.
local submap_helpers = require("submap-helpers")

local submap_options_per_key = {
	-- zoxide | fzf -> copy selected path to the clipboard (no newlines).
	-- bash -c so zoxide's interactive-only shell function is not required;
	-- the kitty window auto-closes when fzf exits (pick or esc).
	z = {
		label = "zlookup",
		-- `>/dev/null 2>&1`: wl-copy 2.3.0 daemonizes but only detaches
		-- stdin/stdout; stderr would keep the kitty pty open forever
		-- (see .opencode/plans/kitty-wlcopy-investigation.md).
		exec_cmd = "kitty --class kitty-float-z bash -c 'zoxide query -l | fzf | wl-copy -n >/dev/null 2>&1'",
	},
	-- qalc calculator: toggle the `calc` special workspace (scratchpad).
	-- qalc is launched at session start (hyprland.lua) and pinned into
	-- special:calc (window-workspace-rules.lua); this only shows/hides it.
	c = {
		label = "calculator",
		exec_cmd = "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"calc\")'",
	},
}

submap_helpers.define_submap("utils", "SUPER+U", submap_options_per_key)