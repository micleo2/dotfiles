-- The only way into dotfiles-private (addresses, hostnames, per-machine
-- files). Nothing else in this config builds a path into that repo.
local M = {}

local root = os.getenv("DOTFILES_PRIVATE") or (os.getenv("HOME") .. "/dotfiles-private")

-- $HOSTNAME is a bash variable and is not in Hyprland's environment.
local function hostname()
	local f = assert(io.open("/etc/hostname"), "dotfiles-private: cannot read /etc/hostname")
	local name = f:read("l"):match("^%s*(.-)%s*$")
	f:close()
	return name
end

-- No fallback for a missing file: it means a broken setup, and a silent
-- default once hid that subtractive's lock_on_start was never committed.
--
-- Loaded through require, not dofile: Hyprland only watches files that its
-- require searcher resolves, so a dofile'd file never triggers auto-reload.
-- dir goes in front of package.path, not in place of it, so the file's own
-- requires (submap-builder) still resolve. require caches by bare name, so a
-- name already loaded from elsewhere would silently return that module.
local function load(dir, name)
	local path = dir .. "/" .. name .. ".lua"
	local f = io.open(path)
	if not f then
		error("dotfiles-private: missing " .. path)
	end
	f:close()
	assert(not package.loaded[name], "dotfiles-private: module name '" .. name .. "' is already loaded")

	local saved = package.path
	package.path = dir .. "/?.lua;" .. saved
	local ok, result = pcall(require, name)
	package.path = saved
	if not ok then
		error(result, 0)
	end
	return result
end

-- Runs <root>/common/hypr/<name>.lua and returns its result.
function M.load_common(name)
	return load(root .. "/common/hypr", name)
end

-- Path of <root>/common/hypr/<name>.lua, for opening it in an editor.
function M.common_path(name)
	return root .. "/common/hypr/" .. name .. ".lua"
end

-- Runs <root>/hosts/<hostname>/hypr/<name>.lua and returns its result.
function M.load_host(name)
	return load(root .. "/hosts/" .. hostname() .. "/hypr", name)
end

return M
