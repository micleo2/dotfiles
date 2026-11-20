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
local function load(path)
	local f = io.open(path)
	if not f then
		error("dotfiles-private: missing " .. path)
	end
	f:close()
	return dofile(path)
end

-- Runs <root>/common/hypr/<name>.lua and returns its result.
function M.load_common(name)
	return load(root .. "/common/hypr/" .. name .. ".lua")
end

-- Runs <root>/hosts/<hostname>/hypr/<name>.lua and returns its result.
function M.load_host(name)
	return load(root .. "/hosts/" .. hostname() .. "/hypr/" .. name .. ".lua")
end

return M
