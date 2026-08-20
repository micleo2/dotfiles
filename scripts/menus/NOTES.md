# Browser menu — findings & todos

rofi menu (`browser-menu.sh`) for opening sites in specific browsers, with
**single-tab behavior**: if the site is already open in Firefox — even a
background tab — activate that tab instead of opening a duplicate.

Menu entries:

| label     | browser  | url                              |
|-----------|----------|----------------------------------|
| syncthing | firefox  | http://localhost:8384/           |
| keybard   | chromium | https://captdeaf.github.io/keybard/ |
| messenger | firefox  | https://www.messenger.com        |
| home assistant | firefox | https://ha.michael7.me/    |

Only labels show in rofi; links are resolved in a `case`/table lookup.

## Files

- `browser-menu.sh` — menu + focus logic (working, verified; **BiDi path wired in**
  and live-tested: firefox entries try BiDi first, fall back to the legacy
  `systemd-run` + window-wait path on exit 2 / timeout)
- `bidi-tab.py` — raw WebDriver BiDi client for Firefox's debug port
  (live-tested & verified: reuse and cold paths both work)

## Verified findings

### Hyprland focus (0.56.2)

- Legacy dispatch is dead: `hyprctl dispatch focuswindow "address:0x…"` and
  even `--batch "dispatch …; dispatch …"` fail — args are parsed as Lua
  (`expected a dispatcher`).
- Use: `hyprctl dispatch "hl.dsp.focus({ window = 'address:0x…' })"`.
  It **auto-follows the window's workspace** (no separate `dispatch workspace`).
- `max_by(.focusHistoryID)` from `hyprctl clients -j` = most recently
  focused window; that's the window a relaunched browser drops new tabs into.
- A window's title only reflects the **active tab** — the WM has zero
  visibility into background tabs. That's the hard limit that forces the
  BiDi approach for true single-tab behavior.
- Detach browser launches with `systemd-run --user --quiet --collect`.
- `mapped` field on a client = actually focusable; poll it on cold start.

### Firefox debug port (WebDriver BiDi, NOT CDP)

- `firefox --remote-debugging-port 9229` speaks **WebDriver BiDi over
  WebSocket** on Fx 153. No HTTP `/json` discovery, CDP calls 404.
- WS endpoint: `ws://127.0.0.1:9229/session` (bare port is just HTTPD).
- Handshake: **send NO Origin header** — absence is accepted; a wrong
  `Origin: …` gets `400 incorrect Origin header`.
- JSON-RPC. `session.new` **requires** a `capabilities` object
  (`{"capabilities": {}}`).
- Command set needed:
  - `session.new`
  - `browsingContext.getTree` → all tabs w/ `context` id + `url`
  - `browsingContext.activate {context}` → switch to a background tab
    (verified: brings a background tab forward; WM title follows)
  - `browsingContext.create {type: "tab", context: <live id>}` → open a
    **blank** tab in the same window as the ref context, then
    `browsingContext.navigate {context, url}`
  - `browsingContext.close {context}`
  - `session.end` → **must be sent on the same connection** that created
    the session
- Spec: https://w3c.github.io/webdriver-bidi/

### Fx 153 `create` gotchas (cost the first cold-open)

- `browsingContext.create {type:"tab", url}` **silently ignores `url`** —
  returns success, but a **blank** tab appears and never navigates. Do not
  rely on url-in-create; always create blank + explicit `navigate`.
- A bare `create {type:"tab"}` (no ref) can fail with
  `DiscardedBrowsingContextError` / `waitForCurrentWindowGlobal` when it
  tries to anchor to the "current" window. **Anchoring with
  `context: <a live tab's id>` resolves it.**
- `getTree` top-level `contexts[]` = the tabs (each has `parent: null` and
  a `clientWindow` id); nested `children` are sub-documents/frames. Match
  on the top-level `url` only.
- `context` ids are **not stable across sessions** (a fresh `session.new`
  re-IDs the same tabs), so never persist/compare ids across runs; always
  `getTree` fresh within the one session you created.

### Reuse Tabs extension actively conflicts with the BiDi cold path

- While it was installed it **killed the BiDi-created blank tab** before
  `navigate` could run (it dedups exact-URL tabs on load-complete; two
  `about:blank` tabs = duplicate). Symptom: create "succeeds", the tab
  vanishes from `getTree`, `close` says "not found". Uninstall it for the
  BiDi path to be reliable.

### The session-leak gotcha (cost us a restart)

- Firefox allows exactly **one** BiDi session per process (Bug 1720707);
  any `session.new` with a session active → "Maximum number of active sessions".
- Teardown only happens via `session.end` on the session's own connection.
  A process that connected + `session.new` and then exits **without**
  sending `session.end` leaks the slot until Firefox restarts.
- Implication: `bidi-tab.py` opens a *new* connection per run and MUST
  `session.end` before exiting (done in `finally`), and must be robust
  against its own crash (e.g. don't let a stray `session.new` out if the
  rest may fail — it does: `session.end` is in `finally`). It also traps
  SIGTERM → `SystemExit` so a `timeout`-kill still runs `finally` and
  releases the session instead of leaking it.
- If the leaked-state error ever appears: **restart Firefox**.

### Reuse Tabs extension (alternative — now actively harmful)

- 18-line WebExtension: on tab `load complete`, find another tab with the
  exact same URL → activate it, close the new one.
- Correct but **flashes** (new tab must fully load before dedup can act),
  matches exact URLs only (misses SPA state changes), and is global
  (dedupes everything, not just menu sites).
- **Now proven harmful**: it killed the BiDi-created blank tab before
  `navigate` ran (exact-URL dedup on two `about:blank` tabs), breaking the
  cold path. See the "actively conflicts" note above.
- Installed persistently in the profile as
  `extensions/{4d5b282b-e4b4-450d-80fa-9253a3014b20}.xpi` (also referenced in
  `prefs.js` `extensions.webextensions.uuids` +
  `browser.uiCustomization.state`). To remove: stop Firefox, delete the
  `.xpi`, drop both `prefs.js` entries, restart.
- Audited from the XPI; no native-host/remote parts.
- **Uninstall recommended** once the BiDi path is trusted.

## Known warts

1. Menu's BiDi step adds latency only on the happy path (one WS round-trip,
   sub-second). It runs before the focus, so a slow/absent port now costs a
   `timeout 15` wait **only if the port accepts connections and then hangs**;
   a refused port returns immediately (verified).
2. BiDi success path (reuse **and** cold) now focuses the MRW firefox window
   **immediately** — no title poll. On cold open the new tab's window title is
   blank/URL until load, but the tab already lives in the MRW firefox window
   (where BiDi created/activated it), so waiting for the title is only latency.
   `navigate` returns on navigation-commit (load start), so the user sees the
page load. Tradeoff: with *multiple* firefox windows this assumes the
    BiDi-anchored window is the MRW one (true for the single-window case); the
    legacy path still uses `mrw_by_class_title`.
3. **Unresolved (2026-08-19)**: on a reuse, the workspace jump is correct but
   the *wrong window* ends up focused on the landing workspace. Two suspects,
   neither confirmed (could not isolate FFM: live-session mouse moves defeat
   `ydotool` pointer parking):
   - `follow_mouse = 1` (hyprland.lua): `hl.dsp.focus` itself works — the
     `address:` selector picks the exact target in multi-window tests (3/3) —
     but after the dispatch auto-switches workspaces, FFM can re-evaluate the
     stationary pointer and re-focus whatever window sits under the cursor on
     the landing workspace.
   - Multiple firefox windows: `mrw_by_class` focuses the MRW firefox window,
     which need not be the one BiDi activated/created the tab in (BiDi has no
     address↔clientWindow mapping, so the menu can't target it precisely).
   Possible fixes to try later: briefly toggle FFM around the dispatch,
   `mousemove` the pointer into the target window's rect first, or have
   `bidi-tab.py` report the target window's active-tab title pre-activate and
   match on class+title instead of MRW.

## Todos

- [x] fix `have_session` wart in `bidi-tab.py` (init `False`, set `True`
      only after a successful `session.new`, so `finally` won't send a
      stray `session.end` when no session was created)
- [x] `chmod +x bidi-tab.py`
- [x] restart Firefox with `--remote-debugging-port 9229` (also trap
      SIGTERM in `bidi-tab.py` so a `timeout` kill can't leak the session)
- [x] live-test `bidi-tab.py 9229 http://localhost:8384/`:
      - [x] reuse path → exit 0, no flash, background tab comes forward
            (verified: activate flips the active tab; Hyprland title follows)
      - [x] cold path → exit 1, single new tab, no duplicate later
            (required the create-gotcha fixes: anchored create + navigate)
- [x] wire into `browser-menu.sh`: for firefox, try `bidi-tab.py 9229 $url`
      first; on exit 2 / connection refused, fall back to the existing
      `systemd-run` + window-wait path; still `hl.dsp.focus` the hyprland
      window afterward (BiDi `activate` focuses the tab but not the WM
      window). Verified: reuse, cold-open, and port-down fallback all behave.
- [x] keybard/chromium left alone (single site, Fx-only BiDi; chromium
      would need the CDP `--remote-debugging-port` dance instead) — the menu
      gates the BiDi path on `browser == firefox`, so chromium is untouched.
- [x] decide: uninstall Reuse Tabs — **done** (uninstalled; verified the
      `.xpi` is gone from the profile's `extensions/`)
- [x] persist the `--remote-debugging-port` flag — owner decided: it goes
      into the hyprland config keybind and the `.desktop` file (user edits),
      AND now into the menu's own legacy cold launch (`browser-menu.sh`
      appends `--remote-debugging-port $FIREFOX_BIDI_PORT` when it has to
      `systemd-run` a firefox, so a fully cold path starts BiDi-capable)
      — **verified end-to-end**: cold launch → 9229 listening within ~5 s
      → BiDi `getTree` round-trip OK on the menu-launched instance.
      (Two regressions in this wiring, both argv-arity bugs invisible to
      `ps`, which joins argv with spaces: first I passed
      `"--remote-debugging-port $PORT"` as ONE quoted string (one argument,
      embedded space) — firefox silently ignores it, port never binds;
      journal tells: systemd **quotes argv elements containing spaces**.
      Second attempt "fixed" it with `launch+=(a, b)` — but bash treats the
      comma as a literal, so the flag became `--remote-debugging-port,`.
      Correct: `launch+=("--remote-debugging-port" "$PORT")`, verified via
      `/proc/<pid>/cmdline` NUL-splitting.)
- [x] cleanup scratch: `/tmp/opencode/bidi*.py|*.mjs`, `/tmp/reuse-tabs/`