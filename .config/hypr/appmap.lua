-- App map: tap SUPER + A to enter a one-key submap; the next plain key
-- launches or focuses an app. Escape or any unmapped key cancels.
--
-- Each entry:
--   cmd          : command to run when no window matches (or always, when
--                  singleton = false)
--   class        : WM_CLASS pattern for app-launch-or-focus --class
--   title        : window-title pattern for app-launch-or-focus --title
--                  (exactly one of class/title; no cross-field fallback)
--   singleton    : default true; false runs cmd directly (new instance)
--   webapp/name/url : use webapp-launch-or-focus instead (Chromium --app)
--
-- Absolute paths: Hyprland (launched by the wayland-wm@ session service) has
-- no ~/.local/bin in its PATH, so bare names would fail to resolve.
local bin = (os.getenv("HOME") or "") .. "/.local/bin"
local app_lof = bin .. "/app-launch-or-focus"
local webapp_lof = bin .. "/webapp-launch-or-focus"

local apps = {
	-- native apps
	b = { class = "blender", cmd = "blender" },
	d = { class = "discord", cmd = "discord" },
	f = { class = "org.freecad.FreeCAD", cmd = "freecad" },
	i = { class = "org.inkscape.Inkscape", cmd = "inkscape" },
	o = { class = "md.obsidian.Obsidian", cmd = "obsidian" },
	s = { class = "Spotify", cmd = "spotify" },
	t = { singleton = false, cmd = "kitty" },
	y = { singleton = false, cmd = "kitty yazi" },
	-- bottles apps
	k = {
		title = "MakeraStudio",
		cmd = "gtk-launch bottles-MakeraStudio-MakeraStudio.desktop",
	},
	p = {
		title = "Adobe Photoshop 2024",
		cmd = "gtk-launch bottles-Photoshop-2024-Photoshop.desktop",
	},
	-- webapps
	m = { webapp = true, name = "Messenger", url = "https://www.messenger.com/" },
	w = { webapp = true, name = "WhatsApp", url = "https://web.whatsapp.com/" },
}

local function cmd_for(app)
	if app.webapp then
		return string.format("%s '%s' '%s'", webapp_lof, app.name, app.url)
	elseif app.singleton ~= false then
		if app.title then
			return string.format("%s --title '%s' %s", app_lof, app.title, app.cmd)
		end
		return string.format("%s '%s' %s", app_lof, app.class, app.cmd)
	end
	return app.cmd
end

hl.bind("SUPER + A", hl.dsp.submap("appmap"))

-- Second arg "reset": auto-close the submap after any key inside it fires.
hl.define_submap("appmap", "reset", function()
	for key, app in pairs(apps) do
		hl.bind(key, hl.dsp.exec_cmd(cmd_for(app)))
	end
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("catchall", hl.dsp.submap("reset"))
end)
