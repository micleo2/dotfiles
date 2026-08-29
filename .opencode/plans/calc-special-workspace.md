# Plan: qalc in an eagerly-created special workspace, `c` = pure toggle

## Goal
`c` in the `utils` submap (SUPER+U) becomes a **pure toggle** of a special
workspace `calc`. qalc is launched eagerly at session start and pinned into
`special:calc` **silently** (no visible overlay at boot). Hiding/showing keeps
the qalc process alive (scratchpad). No existence checks, no launch-on-demand
logic in the keybind.

`z` (zoxide/fzf copy) is out of scope.

## Verified facts (Hyprland 0.56.2 source, /tmp/opencode/hypr-src)
- **Silent placement via window rule**: the `workspace` effect value is a
  free-form string (`CLuaConfigString`, LuaBindingsInternal.hpp:62) and at map
  time a `silent` token in it suppresses the show:
  `Window.cpp:2298` (`WORKSPACEARGS.contains("silent")` → `workspaceSilent`),
  `Window.cpp:2325-2327` (skip `setSpecialWorkspace` when silent). So
  `workspace = "special:calc silent"` places the window in the special ws
  without making it visible, and `special:calc` is created on the window's
  (focused) monitor.
- **Eager launch timing**: `hl.on("hyprland.start", ...)` fires exactly once
  per session — the `start` event is emitted only at renderer init
  (`Renderer.cpp:2060`), **not** on `hyprctl reload`. The existing autostart
  block (hyprland.lua:21-31) is the right home.
- **Pure toggle**: `hl.dsp.workspace.toggle_special(name)`
  (LuaBindingsDispatchers.cpp:1396; `dsp_toggleSpecial` at 1207) finds
  `special:<name>` on any monitor, toggles visibility, and auto-creates the ws
  on the focused monitor if it doesn't exist.
- **dispatch-as-Lua**: `hyprctl dispatch '<lua expr>'` (≥0.55) is the
  established pattern (`scripts/apps/app-launch-or-focus`).
- **Empty-ws destruction**: `misc:close_special_on_empty` defaults to `true`
  (ConfigValues.cpp:502; Window.cpp:591) — killing qalc destroys
  `special:calc`.
- Class match is `re2::RE2::FullMatch` → pattern must consume the whole class.
- The generic `kitty-float-utils` rule (`^kitty-float.*`) keeps providing
  `float`/`center`/`size = "1200 680"` — multiple rules compose.

## Changes (3 files, no new scripts)

### 1. `.config/hypr/hyprland.lua` — eager launch
Add one line to the existing `hl.on("hyprland.start", ...)` block (~line 30):

```lua
	hl.exec_cmd("kitty --class kitty-float-calc qalc")
```

qalc maps shortly after boot → rule (change 2) pins it into `special:calc`
silently. Runs once per session; not re-triggered by `hyprctl reload`.

### 2. `.config/hypr/window-workspace-rules.lua` — silent pin
Next to the existing `kitty-float-utils` rule:

```lua
-- qalc calculator: pin into special workspace `calc` (scratchpad).
-- `silent` places it there without showing the overlay on map (boot / relaunch).
-- The generic kitty-float-utils rule still supplies float/center/size.
hl.window_rule({
	name = "kitty-float-calc-workspace",
	match = { class = "^kitty-float-calc$" },
	workspace = "special:calc silent",
})
```

### 3. `.config/hypr/submap-utils.lua` — `c` is a pure toggle
```lua
	-- qalc calculator: toggle the `calc` special workspace (scratchpad).
	-- qalc is launched at session start (hyprland.lua) and pinned into
	-- special:calc (window-workspace-rules.lua); this only shows/hides it.
	c = {
		label = "calculator",
		exec_cmd = "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"calc\")'",
	},
```

Shell flow: `/bin/sh -c "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"calc\")'"`
→ hyprctl receives the single Lua expression
`hl.dsp.workspace.toggle_special("calc")` → toggles.

## Behavior
- Boot: `special:calc` created on the focused (main/DP-1) monitor, qalc inside,
  overlay NOT shown (silent placement).
- SUPER+U, `c` → overlay appears (qalc floating, 1200×680, work-area centered).
- SUPER+U, `c` → overlay hidden; qalc process retained (same PID, state kept).
- SUPER+U, `c` → back. Repeat freely.
- `hyprctl reload` → no second qalc (start event not re-emitted).

## Edge case: qalc killed
`close_special_on_empty` (default true) destroys `special:calc` when qalc dies.
Next `c`: `toggle_special` auto-creates an EMPTY ws and shows an empty overlay.
qalc must be relaunched manually (it will land in the already-visible overlay).

Optional one-line guard if you don't like that (still inline, no script):
```lua
exec_cmd = "hyprctl clients -j | jq -e 'any(.[]; .class == \"kitty-float-calc\")' >/dev/null || kitty --class kitty-float-calc qalc; hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"calc\")'",
```
(`jq` is installed; the predicate is safe on an empty client list — returns
false. With the silent rule, the relaunched qalc maps ~150 ms later into the
already-shown overlay.)

## Verification (post-approval, live)
1. `luac -p .config/hypr/hyprland.lua .config/hypr/window-workspace-rules.lua .config/hypr/submap-utils.lua`
2. `hyprctl reload` + `hyprctl configerrors` → empty; confirm exactly ONE
   `kitty-float-calc` client, and `special:calc` NOT visible
   (`hyprctl workspaces -j`).
3. SUPER+U `c` → `special:calc` visible; qalc floating [1200,680] centered.
4. SUPER+U `c` → hidden; PID unchanged.
5. SUPER+U `c` → visible; same PID.
6. (If guard chosen) kill qalc PID → SUPER+U `c` → qalc reappears.

## Explicitly NOT doing
- No `z` / kitty changes (deferred).
- No new scripts; no kitty.conf changes; no monitors.lua changes.