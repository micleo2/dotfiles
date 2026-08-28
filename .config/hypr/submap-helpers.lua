local M = {}
local function json_escape(s)
	s = s:gsub("\\", "\\\\")
	s = s:gsub('"', '\\"')
	s = s:gsub("\n", "\\n")
	s = s:gsub("\r", "\\r")
	s = s:gsub("\t", "\\t")
	return s
end

local function submap_ipc_payload(submap_name, submap)
	local parts = {}
	for key, app in pairs(submap) do
		local icon = app.desktop_file or app.name or ""
		table.insert(
			parts,
			string.format(
				'{"key":"%s","label":"%s","icon":"%s"}',
				json_escape(key),
				json_escape(app.label),
				json_escape(icon)
			)
		)
	end
	local json = string.format('{"submap":"%s","entries":[%s]}', json_escape(submap_name), table.concat(parts, ","))
	-- The payload is embedded in a single-quoted sh -c command.
	return json:gsub("'", "'\\''")
end

local function dispatch_qs_submap(submap_name, submap)
	hl.dispatch(hl.dsp.exec_cmd("qs -c retro ipc call submap display '" .. submap_ipc_payload(submap_name, submap) .. "'"))
end

function M.define_submap(submap_name, submap_activation_key, submap_options_per_key)
	hl.bind(submap_activation_key, function()
		dispatch_qs_submap(submap_name, submap_options_per_key)
		hl.dispatch(hl.dsp.submap(submap_name))
	end)

	-- Second arg "reset": auto-close the submap after any key inside it fires.
	hl.define_submap(submap_name, "reset", function()
		for key, submap_opt in pairs(submap_options_per_key) do
			hl.bind(key, hl.dsp.exec_cmd(submap_opt.exec_cmd))
		end
		hl.bind("escape", hl.dsp.submap("reset"))
		-- catchall matches every key INCLUDING bare modifier presses, so a press-triggered
		-- catchall would dismiss the submap the moment Shift is held (hyprwm/Hyprland#10166).
		-- Triggering on release instead gives time to press the S/R key.
		hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
	end)
end

return M
