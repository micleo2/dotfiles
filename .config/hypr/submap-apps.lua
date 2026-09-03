-- App map: tap SUPER + A to enter a submap for launching frequently used applications.

local submap_builder = require("submap-builder")

-- Every entry defines `opts`:
--  A direct gtk-launch
--   { direct = true }
--  A gtk-launch wrapped in app-launch-or-focus
--   { class = "Some.Class" }   match by window class
--   { title = "Window Title" } match by window title
local function make_submap_entry(label, desktop_file, opts)
	opts = opts or {}
	local launch = "gtk-launch " .. desktop_file
	local exec_cmd
	if opts.direct then
		exec_cmd = launch
	elseif opts.class then
		exec_cmd = string.format("app-launch-or-focus '%s' %s", opts.class, launch)
	elseif opts.title then
		exec_cmd = string.format("app-launch-or-focus --title '%s' %s", opts.title, launch)
	else
		error("make_submap_entry(" .. label .. "): needs direct = true, class = ..., or title = ...")
	end
	return { label = label, desktop_file = desktop_file, exec_cmd = exec_cmd }
end

local submap_options_per_key = {
	-- native apps
	b = make_submap_entry("blender", "blender", { class = "blender" }),
	c = make_submap_entry("chromium", "chromium", { direct = true }),
	d = make_submap_entry("discord", "discord", { class = "discord" }),
	e = make_submap_entry("google-messages", "GoogleMessages", { direct = true }),
	f = make_submap_entry("freecad", "org.freecad.FreeCAD", { class = "org.freecad.FreeCAD" }),
	i = make_submap_entry("inkscape", "org.inkscape.Inkscape", { class = "org.inkscape.Inkscape" }),
	l = make_submap_entry("moonlight", "com.moonlight_stream.Moonlight", { class = "com.moonlight_stream.Moonlight" }),
	o = make_submap_entry("obsidian", "obsidian", { class = "md.obsidian.Obsidian" }),
	s = make_submap_entry("spotify", "spotify-launcher", { class = "Spotify" }),
	u = make_submap_entry("bambustudio", "com.bambulab.BambuStudio", { class = "BambuStudio" }),
	y = make_submap_entry("yazi", "yazi", { direct = true }),
	-- bottles apps
	k = make_submap_entry("makera", "bottles-MakeraStudio-MakeraStudio", { title = "MakeraStudio" }),
	p = make_submap_entry("photoshop", "bottles-Photoshop-2024-Photoshop", { title = "Adobe Photoshop 2024" }),
	-- webapps
	a = make_submap_entry("assistant", "HomeAssistant", { direct = true }),
	g = make_submap_entry("gmail", "Gmail", { direct = true }),
	j = make_submap_entry("jellyfin", "Jellyfin", { direct = true }),
	m = make_submap_entry("messenger", "Messenger", { direct = true }),
	r = make_submap_entry("calendar", "Calendar", { direct = true }),
	t = make_submap_entry("youtube", "YouTube", { direct = true }),
	w = make_submap_entry("whatsapp", "WhatsApp", { direct = true }),
}

submap_builder.define_submap("apps", "SUPER+A", submap_options_per_key)
