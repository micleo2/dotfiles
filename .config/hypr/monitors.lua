hl.monitor({
	output = "DP-1",
	mode = "3840x2160@240.0",
	position = "0x1195",
	scale = "2.5",
})

for i = 1, 8 do
	hl.workspace_rule({ workspace = "" .. i, monitor = "DP-1" })
end
-- Hyprland will just reassign this WS when we disable it, so no need to make this conditional
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })

local hdmi_enabled = true
local function toggle_hdmi()
	hdmi_enabled = not hdmi_enabled
	if hdmi_enabled then
		hl.monitor({
			output = "HDMI-A-1",
			mode = "2560x1440@143.85",
			position = "1920x0",
			scale = "1",
			transform = 3,
			disabled = false,
		})
		hl.workspace_rule({ workspace = "2", layout_opts = { direction = "down" } })
	else
		hl.monitor({
			output = "HDMI-A-1",
			disabled = true,
		})
		hl.workspace_rule({ workspace = "2", layout_opts = { direction = "right" } })
	end
end
-- start with the monitor turned off
toggle_hdmi()
hl.bind("SUPER + M", toggle_hdmi)
