-- Top bar map: tap SUPER + T, then a letter to open that bar popup with the
-- keyboard cursor on its first control (see ui/Popup.qml `openWithCursor`).
-- The submap resets after the keypress, so from there the popup owns the
-- keyboard: j/k move, h/l adjust, Enter activates, Escape closes.
local submap_builder = require("submap-builder")

local function panel(target)
	return "qs -c retro ipc call " .. target .. " focus"
end

local submap_options_per_key = {
	n = { label = "network", exec_cmd = panel("network") },
	b = { label = "bluetooth", exec_cmd = panel("bluetooth") },
	d = { label = "display", exec_cmd = panel("display") },
	c = { label = "caffeinate", exec_cmd = "qs -c retro ipc call idle toggle" },
	p = { label = "power", exec_cmd = panel("battery") },
	v = { label = "volume", exec_cmd = panel("volume") },
	s = { label = "system", exec_cmd = panel("system") },
}

submap_builder.define_submap("topbar", "SUPER+T", submap_options_per_key)
