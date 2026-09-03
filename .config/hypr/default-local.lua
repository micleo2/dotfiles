-- Per-machine settings, tracked defaults. hyprland.lua loads `local.lua`
-- from this directory when it exists and falls back to this file otherwise.
-- `local.lua` is gitignored: to stand up a new machine, copy this file to
-- local.lua next to it and change what differs.
return {
	-- Lock the screen as the session starts. With greetd auto-login the
	-- shell's lock screen then doubles as the login screen. Leave off on a
	-- stationary machine that should boot straight to the desktop.
	lock_on_start = false,
}
