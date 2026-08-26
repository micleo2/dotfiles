-- App map: tap SUPER + A to enter a one-key submap; the next plain key
-- launches or focuses an app. Escape or any unmapped key cancels.
--
-- While the submap is active, a quickshell overlay (retro/appmap module)
-- shows every key and its label; it is driven over IPC from the payload
-- built below, so it can never drift from the actual binds.
--
-- Each entry:
--   cmd          : command to run when no window matches (or always, when
--                  singleton = false)
--   class        : WM_CLASS pattern for app-launch-or-focus --class
--   title        : window-title pattern for app-launch-or-focus --title
--                  (exactly one of class/title; no cross-field fallback)
--   singleton    : default true; false runs cmd directly (new instance)
--   webapp/name/url : use webapp-launch-or-focus instead (Chromium --app)
--   label        : display name for the overlay (cosmetic only)
--   icon         : overlay icon, derived from desktop_file (or name for
--                  webapps); cosmetic only
--
local app_launch_or_focus = "app-launch-or-focus"
local webapp_launch_or_focus = "webapp-launch-or-focus"

local apps = {
	-- native apps
	b = { label = "blender", class = "blender", desktop_file = "blender" },
	c = { label = "chromium", singleton = false, desktop_file = "chromium" },
	d = { label = "discord", class = "discord", desktop_file = "discord" },
	f = { label = "freecad", class = "org.freecad.FreeCAD", desktop_file = "org.freecad.FreeCAD" },
	i = { label = "inkscape", class = "org.inkscape.Inkscape", desktop_file = "org.inkscape.Inkscape" },
	o = { label = "obsidian", class = "md.obsidian.Obsidian", desktop_file = "obsidian" },
	s = { label = "spotify", class = "Spotify", desktop_file = "spotify-launcher" },
	x = { label = "firefox", singleton = false, desktop_file = "firefox" },
	y = { label = "yazi", singleton = false, desktop_file = "yazi" },
	-- bottles apps
	k = {
		label = "makera",
		title = "MakeraStudio",
		desktop_file = "bottles-MakeraStudio-MakeraStudio",
	},
	p = {
		label = "photoshop",
		title = "Adobe Photoshop 2024",
		desktop_file = "bottles-Photoshop-2024-Photoshop",
	},
	-- webapps
	m = { label = "messenger", webapp = true, name = "Messenger", url = "https://www.messenger.com/" },
	w = { label = "whatsapp", webapp = true, name = "WhatsApp", url = "https://web.whatsapp.com/" },
}

local function json_escape(s)
	s = s:gsub("\\", "\\\\")
	s = s:gsub('"', '\\"')
	s = s:gsub("\n", "\\n")
	s = s:gsub("\r", "\\r")
	s = s:gsub("\t", "\\t")
	return s
end

local function appmap_payload()
	local parts = {}
	for key, app in pairs(apps) do
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
	local json = string.format('{"entries":[%s]}', table.concat(parts, ","))
	-- The payload is embedded in a single-quoted sh -c command.
	return json:gsub("'", "'\\''")
end

local function cmd_for(app)
	if app.webapp then
		return string.format("%s '%s' '%s'", webapp_launch_or_focus, app.name, app.url)
	end
	local launch_app_cmd = ""
	if app.desktop_file ~= nil then
		launch_app_cmd = "gtk-launch " .. app.desktop_file
	else
		assert(false, "don't know how to launch this app")
	end
	if app.singleton == false then
		return launch_app_cmd
	end
	if app.title == true then
		return string.format("%s --title '%s' %s", app_launch_or_focus, app.title, launch_app_cmd)
	end
	return string.format("%s '%s' %s", app_launch_or_focus, app.class, launch_app_cmd)
end

hl.bind("SUPER + A", function()
	hl.dispatch(hl.dsp.exec_cmd("qs -c retro ipc call appmap display '" .. appmap_payload() .. "'"))
	hl.dispatch(hl.dsp.submap("appmap"))
end)

-- Second arg "reset": auto-close the submap after any key inside it fires.
hl.define_submap("appmap", "reset", function()
	for key, app in pairs(apps) do
		hl.bind(key, hl.dsp.exec_cmd(cmd_for(app)))
	end
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("catchall", hl.dsp.submap("reset"))
end)
