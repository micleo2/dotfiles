local M = {}

-- Quickshell instance that renders the submap overlay (submap/SubmapOverlay.qml).
local QS_CONFIG = "retro"
-- Name of the meta submap built by generate_helper_submap.
local HELPER_SUBMAP_NAME = "helper"

-- Every submap defined through this module, in definition order, so
-- generate_helper_submap can list them; the two sets guard against a submap
-- name or an activation key being claimed twice (Hyprland would silently keep
-- only the last one).
local defined_submaps = {}
local claimed_names = {}
local claimed_keys = {}

local function json_escape(s)
	s = s:gsub("\\", "\\\\")
	s = s:gsub('"', '\\"')
	s = s:gsub("\n", "\\n")
	s = s:gsub("\r", "\\r")
	s = s:gsub("\t", "\\t")
	return s
end

-- The overlay renders one text row per entry ("<key> -> <label>"), nothing
-- else -- so the payload carries nothing else.
local function submap_ipc_payload(submap_name, submap_options_per_key)
	local parts = {}
	for key, submap_opt in pairs(submap_options_per_key) do
		table.insert(parts, string.format('{"key":"%s","label":"%s"}', json_escape(key), json_escape(submap_opt.label)))
	end
	local json = string.format('{"submap":"%s","entries":[%s]}', json_escape(submap_name), table.concat(parts, ","))
	-- The payload is embedded in a single-quoted sh -c command.
	return json:gsub("'", "'\\''")
end

local function display_cmd(submap_name, submap_options_per_key)
	return "qs -c "
		.. QS_CONFIG
		.. " ipc call submap display '"
		.. submap_ipc_payload(submap_name, submap_options_per_key)
		.. "'"
end

-- Entries whose `visible` predicate returns false are left out of the overlay
-- (their key stays bound -- this hides an option that does not apply right
-- now, it does not disable it).
local function visible_entries(submap_options_per_key)
	local shown = {}
	for key, submap_opt in pairs(submap_options_per_key) do
		if not submap_opt.visible or submap_opt.visible() then
			shown[key] = submap_opt
		end
	end
	return shown
end

local function has_conditional_entries(submap_options_per_key)
	for _, submap_opt in pairs(submap_options_per_key) do
		if submap_opt.visible then
			return true
		end
	end
	return false
end

-- Show the QS overlay for a submap and switch Hyprland into it. The overlay
-- keys itself off the submap event, so both halves have to happen together.
-- A submap with a fixed entry list renders the same payload every time, so it
-- is built once at config-parse time; only conditional ones are rebuilt per
-- keypress.
local function submap_entry_action(submap_name, submap_options_per_key)
	local fixed_cmd
	if not has_conditional_entries(submap_options_per_key) then
		fixed_cmd = display_cmd(submap_name, submap_options_per_key)
	end

	return function()
		hl.dispatch(hl.dsp.exec_cmd(fixed_cmd or display_cmd(submap_name, visible_entries(submap_options_per_key))))
		hl.dispatch(hl.dsp.submap(submap_name))
	end
end

-- Every submap closes on escape, and on the release of any other key.
-- catchall matches every key INCLUDING bare modifier presses, so a
-- press-triggered catchall would dismiss the submap the moment Shift is held
-- (hyprwm/Hyprland#10166). Triggering on release instead leaves time to
-- finish a shifted binding like SHIFT+S.
local function bind_submap_exits()
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
end

-- Claim a (name, activation key) pair, so a copy-pasted submap file fails
-- loudly at parse time instead of quietly shadowing an existing submap.
local function claim(submap_name, submap_activation_key)
	assert(not claimed_names[submap_name], "submap '" .. submap_name .. "' is already defined")
	assert(
		not claimed_keys[submap_activation_key],
		"submap key '"
			.. submap_activation_key
			.. "' is already bound to submap '"
			.. tostring(claimed_keys[submap_activation_key])
			.. "'"
	)
	claimed_names[submap_name] = true
	claimed_keys[submap_activation_key] = submap_name
end

function M.define_submap(submap_name, submap_activation_key, submap_options_per_key)
	claim(submap_name, submap_activation_key)

	for key, submap_opt in pairs(submap_options_per_key) do
		local where = submap_name .. "[" .. key .. "]"
		assert(type(submap_opt.label) == "string", where .. ": needs a string label")
		-- An entry either shells out (exec_cmd) or runs Lua in-process (action),
		-- for things the shell cannot reach, like the active workspace.
		assert(
			type(submap_opt.exec_cmd) == "string" or type(submap_opt.action) == "function",
			where .. ": needs a string exec_cmd or a function action"
		)
		assert(
			submap_opt.visible == nil or type(submap_opt.visible) == "function",
			where .. ": visible must be a function"
		)
	end

	table.insert(defined_submaps, {
		name = submap_name,
		activation_key = submap_activation_key,
		options = submap_options_per_key,
	})

	hl.bind(submap_activation_key, submap_entry_action(submap_name, submap_options_per_key))

	-- Second arg "reset": auto-close the submap after any key inside it fires.
	hl.define_submap(submap_name, "reset", function()
		for key, submap_opt in pairs(submap_options_per_key) do
			hl.bind(key, submap_opt.action or hl.dsp.exec_cmd(submap_opt.exec_cmd))
		end
		bind_submap_exits()
	end)
end

-- Meta submap: lists every submap defined so far next to its activation key.
-- Pressing one of those keys jumps straight from here into that submap.
--
-- Call this AFTER all define_submap calls, so the registry is complete.
--
-- Default key is SUPER + ? -- written as SHIFT+slash because Hyprland matches
-- the unshifted keysym plus an exact modmask.
function M.generate_helper_submap(activation_key)
	activation_key = activation_key or "SUPER+SHIFT+slash"
	claim(HELPER_SUBMAP_NAME, activation_key)

	-- Entries are keyed by activation key and labelled with the submap name,
	-- so the overlay reads "SUPER+A -> apps".
	local helper_options_per_key = {}
	for _, submap in ipairs(defined_submaps) do
		helper_options_per_key[submap.activation_key] = { label = submap.name }
	end

	hl.bind(activation_key, submap_entry_action(HELPER_SUBMAP_NAME, helper_options_per_key))

	hl.define_submap(HELPER_SUBMAP_NAME, "reset", function()
		for _, submap in ipairs(defined_submaps) do
			hl.bind(submap.activation_key, submap_entry_action(submap.name, submap.options))
		end
		bind_submap_exits()
	end)
end

return M
