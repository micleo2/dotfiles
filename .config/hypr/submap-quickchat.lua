-- Quick-chat map: tap SUPER+N to enter a submap that types a Rocket League
-- quick chat into the focused game window. wtype speaks the virtual-keyboard
-- protocol, so the keystrokes reach the XWayland/Proton window like a real
-- keyboard would.
local submap_builder = require("submap-builder")

-- Rocket League's default "Text Chat" / "Team Text Chat" keys.
local ALL_CHAT_KEY = "t"
local TEAM_CHAT_KEY = "y"

-- Single-quote a string for sh.
local function sh_quote(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Open the chat box, type `text`, send it. `-s` waits for the chat box to
-- appear before the text goes in; `-d` spaces the keystrokes out so the
-- game, which polls input once per frame, doesn't collapse them.
local function chat(text, opts)
	opts = opts or {}
	local open_key = opts.team and TEAM_CHAT_KEY or ALL_CHAT_KEY
	local exec_cmd = string.format("wtype -d 15 -k %s -s 150 %s -k Return", open_key, sh_quote(text))
	return { label = text, exec_cmd = exec_cmd }
end

local submap_options_per_key = {
	-- compliments (everyone)
	n = chat("Nice shot!"),
	g = chat("Great pass!"),
	w = chat("What a save!"),
	t = chat("Thanks!"),
	p = chat("What a play!"),
	c = chat("Great clear!"),
	-- reactions (everyone)
	o = chat("OMG!"),
	u = chat("Noooo!"),
	h = chat("Close one!"),
	k = chat("Calculated."),
	v = chat("Savage!"),
	z = chat("Siiiick!"),
	q = chat("gg"),
	-- apologies (everyone)
	s = chat("Sorry!"),
	m = chat("My bad..."),
	l = chat("Whoops..."),
	r = chat("No problem."),
	-- info (team)
	i = chat("I got it!", { team = true }),
	a = chat("All yours.", { team = true }),
	b = chat("Need boost!", { team = true }),
	d = chat("Defending...", { team = true }),
	e = chat("Centering!", { team = true }),
	x = chat("Take the shot!", { team = true }),
	f = chat("Faking.", { team = true }),
	j = chat("Incoming!", { team = true }),
}

submap_builder.define_submap("quick-chat", "SUPER+N", submap_options_per_key)
