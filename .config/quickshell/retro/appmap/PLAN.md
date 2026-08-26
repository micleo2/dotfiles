# Plan: Super+A appmap overlay (which-key style, via IPC)

Status: IPC data path VERIFIED (2026-08-26): labels in `appmap.lua` flow
through to the overlay. Remaining: visual polish (retro card / key chips /
title / footer) and manual key-path tests (pick key, esc, catchall).
Environment verified: Hyprland 0.56.2, quickshell 0.3.1,
config dir `~/.config/hypr` (repo: `/home/mal/dotfiles/.config/hypr`),
quickshell module `retro` in `/home/mal/dotfiles/.config/quickshell/retro`.

## Data flow

`appmap.lua` builds a JSON payload from the same `apps` table the binds use.
On `SUPER + A`, it `hl.dispatch`es
`qs -c retro ipc call appmap display '{"entries":[...]}'` followed by
`hl.dsp.submap("appmap")`. The QML `IpcHandler` parses the payload and shows;
a `submap` raw event whose data is not `appmap` hides (covers every exit
path: pick a key, escape, catchall — the submap is defined with "reset").
No files, no cache: data is always in sync by construction.

### Verified API facts (installed quickshell 0.3.1)
- `IpcHandler` functions need EXPLICITLY typed params or they are not
  registered: `function display(payload: string): void`. `string` args pass
  through verbatim (src/io/ipchandler.hpp docs + resolve() in ipchandler.cpp).
- **BUG 1 (0.3.1 CLI): an IpcHandler function named after an `ipc`
  subcommand (`show`/`call`/`wait`/`listen`/`prop`) is hijacked by the CLI
  parser and never called: `qs ipc call appmap show '<json>'` parses as
  `qs ipc show appmap '<json>'` (metadata dump / parse error). Proven:
  `call brightness up wait` -> "Signal not found" (parsed as `ipc wait`).
  Workaround: use a non-colliding name (`display`).
- **BUG 2 (0.3.1 CLI): a bare JSON ARRAY argument is mangled by the
  CLI11 vector tokenizer — `[` `]` stripped, split on top-level commas
  (upstream PR quickshell-mirror/quickshell#22 documents identical
  behavior). `qs ipc call t f '[{"a":1},{"b":2}]'` -> "1 required but 2
  provided". Workaround: wrap the array in an object:
  `{"entries":[...]}` parses as a single argument. QML side reads
  `JSON.parse(payload).entries`.
- `Hyprland` singleton: `import Quickshell.Hyprland`, signal
  `rawEvent(HyprlandIpcEvent)`; event has readonly `name`/`data` QStrings
  (quickshell-hyprland-ipc.qmltypes).
- `hl.bind(keys, function)` — a bound function may `hl.dispatch()` multiple
  times (Hyprland source LuaBindingsToplevel.cpp; repo precedent
  hyprland.lua:255-264).
- CLI syntax already used in repo: `qs -c retro ipc call <target> <fn>`
  (hyprland.lua:225, 310).
- `QT_FONT_DPI=192` (hyprland.lua:460): font sizes need 2x tuning; sizes are
  guesses refined via the preview hook.
- **0.3.x has no `qs reload` subcommand** (gone since 0.3.0): the running
  shell hot-reloads itself via file watcher when any watched QML file
  changes (src/core/rootwrapper.cpp `onWatchedFilesChanged -> reloadGraph`).
  Just save the file; give the watcher a second.

## Files

### 1. `.config/hypr/appmap.lua` (edit)
- Add `label` to each of the 12 entries: Blender, Discord, FreeCAD, Inkscape,
  Obsidian, Spotify, Terminal, Yazi, Makera Studio, Photoshop 2024,
  Messenger, WhatsApp.
- Add `local order = { "b","d","f","i","o","s","t","y","k","p","m","w" }`
  (Lua `pairs()` is unordered; single 4x3 grid, no group headers — user
  decision).
- Add `json_escape(s)` (backslash, quote, control chars) and
  `appmap_payload()` returning `[{"key":"b","label":"Blender"}, ...]` in
  `order`; result is `'`-escaped (`'` -> `'\''`) for `exec_cmd`'s `sh -c`.
- Replace the plain bind:
     hl.bind("SUPER + A", function()
         hl.dispatch(hl.dsp.exec_cmd(
             "qs -c retro ipc call appmap display '" .. appmap_payload() .. "'"))
         hl.dispatch(hl.dsp.submap("appmap"))
     end)
- Submap body (12 binds + escape + catchall, "reset" auto-close) untouched.
- Update header comment to document `label` and the overlay.

### 2. `.config/quickshell/retro/appmap/qmldir` (new)
    module Appmap
    AppmapOverlay 1.0 AppmapOverlay.qml

### 3. `.config/quickshell/retro/appmap/AppmapOverlay.qml` (new)
- `Scope` root: `property bool active`, `property var entries: []`,
  `readonly property bool shown: active && entries.length > 0` (gate so the
  first entry's exec->IPC latency never renders an empty grid; subsequent
  presses show instantly).
- Own `FontLoader`s (shell-root ids are not visible across module files):
  `../fonts/PressStart2P-Regular.ttf` (keys/title/footer),
  `../fonts/CozetteVector.ttf` (labels). `import ".."` for `Config`.
- `IpcHandler { target: "appmap" }`:
     function display(payload: string): void {
         root.entries = JSON.parse(payload).entries;
         root.active = true;
     }
     function preview(): void { root.active = !root.active; }
- `Connections { target: Hyprland; function onRawEvent(event) {
    if (event.name === "submap") root.active = event.data === "appmap";
} }` — one condition covers enter and all exit paths.
- `Variants { model: Quickshell.screens }` -> per-screen `PanelWindow`
  (template: osd/BrightnessOsd.qml): `WlrLayer.Overlay`,
  `WlrKeyboardFocus.None` (must not swallow the submap's keys),
  `exclusiveZone: 0`, `color: "transparent"`, full-width bottom strip,
  content anchored bottom-center with margin.
- Retro card (Bar.qml idiom): `Config.colors.shadow` fill + 2px
  `Config.colors.outline` border (inner Rectangle offset by -2), inner
  padding 16.
- Content: title `SUPER + A` (PressStart2P ~20) -> `GridLayout { columns: 4 }`
  + `Repeater` over `entries`, each card = 48x48 key chip (Config.colors.base
  fill, 2px outline, key glyph ~22 PressStart2P) + centered label (~14
  CozetteVector, Config.colors.text) -> footer `ESC — CANCEL` (dim, ~12).
  No animation (matches OSD precedent).

### 4. `.config/quickshell/retro/shell.qml` (edit)
- `import "appmap" as Appmap` + `Appmap.AppmapOverlay {}` beside
  `Osd.BrightnessOsd {}`.

## Test sequence
1. Save `AppmapOverlay.qml` (or any QML) -> watcher auto-reloads the running
   shell (0.3.x has no `qs reload`). Save `appmap.lua` -> `hyprpm reload`.
2. `qs -c retro ipc show` -> expect target `appmap` with
   `function display(payload: string): void`.
3. `qs -c retro ipc call appmap preview` -> overlay appears with 12 keys in a
   4x3 grid; again -> hides.
4. `qs -c retro ipc call appmap display '{"entries":[...]}'` (object-wrapped,
   see BUG 2) -> overlay shows the given entries; a label changed in
   `appmap.lua` + `hyprpm reload` + `SUPER + A` shows the new label (verified
   2026-08-26 via a temp "BLIPR-TEST" label).
5. `SUPER + A` -> overlay; press `b` -> Blender launches, overlay gone
   (auto-reset); `SUPER + A` + Esc -> gone; `SUPER + A` + unmapped key -> gone.

## Risks / fallbacks
- `submap` exit event misbehaving on 0.56.2 (unlikely; documented IPC event):
  fallback hide-trigger is `Hyprland.activeToplevel` change.
- Font sizes under `QT_FONT_DPI=192` may need adjustment: that is what the
  `preview` hook is for.
- Escape character in payload: labels contain none of `"`/`\`/control, but
  json_escape handles them anyway; the whole payload is wrapped in single
  quotes with `'\''` escaping for sh -c.