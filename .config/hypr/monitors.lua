-- Catch-all. Never matches a listed display; only used when nothing else does.
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

hl.monitor({
	output = "desc:ASUSTek",
	mode = "3840x2160@240.0",
	position = "0x1195",
	scale = "2",
})

for i = 1, 10 do
	hl.workspace_rule({ workspace = "" .. i, monitor = "DP-1" })
end
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })

local side_enabled = false
local function apply_side(enabled)
	side_enabled = enabled
	if enabled then
		hl.monitor({
			output = "desc:Microstep",
			mode = "2560x1440@143.85",
			position = "1920x0",
			scale = "1",
			transform = 3,
			disabled = false,
		})
		hl.workspace_rule({ workspace = "2", layout_opts = { direction = "down" } })
	else
		hl.monitor({
			output = "desc:Microstep",
			disabled = true,
		})
		hl.workspace_rule({ workspace = "2", layout_opts = { direction = "right" } })
	end
end

-- Re-runs on every reload, so read the real state instead of resetting to off.
-- hl.get_monitors() only lists enabled outputs, and config is parsed before
-- the new rules apply, so this reflects the pre-reload state.
local function side_is_on()
	for _, m in ipairs(hl.get_monitors()) do
		if m.description:find("^Microstep") then
			return true
		end
	end
	return false
end

apply_side(side_is_on())

hl.bind("SUPER + M", function()
	apply_side(not side_enabled)
end)
