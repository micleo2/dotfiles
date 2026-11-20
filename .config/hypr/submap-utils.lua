-- Utils map: tap SUPER+U to enter a submap for small utility floats.
--
-- The calculator is the shell's own (quickshell/retro/calc/Calculator.qml),
-- driven by qalc underneath.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	b = { label = "btop", action = submap_builder.float("kitty btop") },
	n = { label = "nvtop", action = submap_builder.float("kitty nvtop") },
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
	-- keymap: the shell's LCD view of the unicorne's layers
	-- (quickshell/retro/keymap), data from `make export` in ~/oss/keyboards.
	k = {
		label = "keymap",
		exec_cmd = "qs -c retro ipc call keymap toggle",
	},
	-- speek: the syncthing selective-sync UI (~/oss/speek). Start its server as
	-- the `speek` user unit if it isn't active (journalctl --user -u speek for
	-- logs), then open/focus the webapp like the SUPER+A webapps.
	e = {
		label = "speek",
		exec_cmd = "bash -c 'systemctl --user is-active -q speek || systemd-run --user --unit=speek --collect python3 ~/oss/speek/main.py --no-open; gtk-launch Speek'",
	},
	-- ntfyupload: pick files in a floating yazi and send each to the ntfy
	-- `clipboard` topic; the server comes from the private ntfy.json.
	u = {
		label = "ntfy-upload",
		action = submap_builder.float("ntfyupload"),
	},
}

submap_builder.define_submap("utils", "SUPER+U", submap_options_per_key)
