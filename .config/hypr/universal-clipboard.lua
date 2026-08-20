-- Universal copy / cut / paste.
--
-- Super+C, Super+X, and Super+V send the chord the focused app actually
-- understands:
--
--   GUI apps:      Ctrl+C (copy)  Ctrl+X (cut)  Ctrl+V (paste)
--   terminals:     Ctrl+Insert (copy)  Ctrl+X (cut)  Shift+Insert (paste)
--   kitty:         Ctrl+Shift+C (copy)  Ctrl+X (cut)  Ctrl+Shift+V (paste)
--
-- In a terminal, Ctrl+C raises SIGINT and Ctrl+V types a literal "v", so
-- those chords are unusable there. Ctrl+Insert and Shift+Insert are the
-- copy/paste chords that (nearly) every terminal emulator and TUI (vim,
-- nvim, helix, tmux, less, ...) already handles, and they also work in
-- most GUI toolkits (GTK, Qt, Electron) -- which is what makes one chord
-- "universal".
--
-- Terminal windows are detected by a window rule below that tags them
-- with the `terminal` tag; the binding checks the tag on the active
-- window and picks the chord accordingly.

-- Regex of terminal window classes to tag. Extend with your terminal's
-- app class, found via:  hyprctl activewindow -j | jq .class
-- (case-sensitive; XWayland terminals report their X11 class).
local terminalClasses =
	"^(Alacritty|kitty|com.mitchellh.ghostty|foot|org.codeberg.dnkl.foot|wezterm|konsole|org.kde.konsole|xterm|st|tilix|termite|urxvt)$"

-- Tag applied to terminal windows by the window rule below.
local terminalTag = "terminal"

-- Fail gracefully on Hyprland builds without the send_key_state Lua
-- dispatcher; without it the bindings would log a Lua error on every
-- keypress.
local ok, sendKeyState = pcall(function()
	return hl.dsp.send_key_state
end)
if not (ok and type(sendKeyState) == "function") then
	if type(print) == "function" then
		print(
			"[universal-clipboard] Hyprland lacks the send_key_state Lua dispatcher; universal copy/paste bindings skipped. Update Hyprland and reload."
		)
	end
	return
end

-- Send one synthetic chord to the focused surface with an explicit
-- key down / up pair.
--
-- Two subtleties (both inherited from the original implementation):
--
-- * No window target on the dispatcher, so the chord is delivered to the
--   focused surface -- which also reaches layer-shell overlays. A virtual
--   keyboard (wtype) cannot do this job while the user holds Super: the
--   physically held Super merges into the injected chord at the seat.
--
-- * The down/up split works around Hyprland's send_shortcut sometimes
--   leaving synthetic key state stuck/repeating:
--   https://github.com/hyprwm/Hyprland/discussions/14099
local function send_shortcut_once(mods, key)
	return function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

		hl.timer(function()
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
		end, { timeout = 50, type = "oneshot" })
	end
end

-- Per-class chord overrides: class -> { copy = {mods, key}, paste = {mods, key} }
--
-- The xterm-family terminal chords (CTRL+Insert / SHIFT+Insert) aren't truly
-- universal. kitty in particular binds SHIFT+Insert to pasting its internal
-- selection buffer (the last text mouse-selected inside kitty), NOT the OS
-- clipboard, so Super+V would paste stale text after copying elsewhere.
-- kitty's real clipboard chords are CTRL+SHIFT+C (copy) and CTRL+SHIFT+V
-- (paste), the shifted-fallback variants of its kitty_mod+c / kitty_mod+v
-- maps (plain ctrl+c still raises SIGINT in the shell). Add your own
-- terminal here with the chords its keybindings use for clipboard copy/paste.
local terminalChordOverrides = {
	kitty = { copy = { "CTRL + SHIFT", "C" }, paste = { "CTRL + SHIFT", "V" } },
}

local function active_window_is_terminal()
	local window = hl.get_active_window()
	if not window then
		return false
	end

	for _, tag in ipairs(window.tags or {}) do
		-- Dynamic tags carry a trailing "*".
		if tag:gsub("%*$", "") == terminalTag then
			return true
		end
	end

	return false
end

-- Chord the focused window understands for an action kind ("copy" or
-- "paste"): a class-specific override wins, then the terminal chord if the
-- active window is tagged as a terminal, then the GUI chord.
local function active_window_chord(kind, default_mods, default_key, terminal_mods, terminal_key)
	local window = hl.get_active_window()
	local override = window and terminalChordOverrides[window.class]
	if override and override[kind] then
		return override[kind][1], override[kind][2]
	end

	if active_window_is_terminal() then
		return terminal_mods, terminal_key
	end

	return default_mods, default_key
end

local function universal_clipboard_shortcut(kind, default_mods, default_key, terminal_mods, terminal_key)
	return function()
		local mods, key = active_window_chord(kind, default_mods, default_key, terminal_mods, terminal_key)
		send_shortcut_once(mods, key)()
	end
end

-- Tag terminal windows. The class value is matched as a regex; the ^...$
-- anchors keep the match exact.
hl.window_rule({
	match = { class = terminalClasses },
	tag = "+" .. terminalTag,
})

hl.bind(
	"SUPER + C",
	universal_clipboard_shortcut("copy", "CTRL", "C", "CTRL", "Insert"),
	{ description = "Universal copy" }
)
hl.bind("SUPER + X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })
hl.bind(
	"SUPER + V",
	universal_clipboard_shortcut("paste", "CTRL", "V", "SHIFT", "Insert"),
	{ description = "Universal paste" }
)

