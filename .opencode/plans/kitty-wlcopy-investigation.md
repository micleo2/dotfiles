# Kitty / wl-copy hang investigation — results so far

## Symptom
`kitty sh -c "echo hi"` closes immediately, but `kitty sh -c "echo hi | wl-copy -n"` (with or without `-n`) never closes — the kitty window lingers forever.

## Root cause: wl-clipboard 2.3.0 daemonizes by default
The installed `/usr/bin/wl-copy` is **wl-clipboard 1:2.3.0-1** (Arch, bugaevc/wl-clipboard). Its man page and binary strings confirm:

> `-f, --foreground` — By default, `wl-copy` forks and serves data requests in the background; this option overrides that behavior, causing `wl-copy` to run in the foreground.

Mechanism (confirmed live via `/proc`):
1. Foreground `wl-copy` reads stdin into a temp FIFO (`/tmp/wl-copy-buffer-XXXXXX/stdin`, mkdtemp), then **forks a background daemon** to serve the Wayland selection and exits immediately.
2. The daemon must stay alive to answer paste requests — Hyprland does **not** cache selections (verified: killing the daemon empties the clipboard instantly).
3. In a pty context, the forked daemon inherits the **pty slave fd**, keeping it open after the shell pipeline has fully exited (bash → zombie).

## PTY harness findings (python `pty.fork`, sampling every 0.5s)
| Case | Result |
|---|---|
| `sh -c "echo hi"` (control) | bash zombie at t=0.5s; master gets data then EIO (clean close) |
| `sh -c "echo hi \| cat"` | same as control — clean |
| `sh -c "echo hi \| sleep 5"` | pty held by `sleep` while alive (expected) |
| `sh -c "echo hi \| wl-copy -n"` | pipeline done <0.5s (bash zombie); **daemon holds pty slave ~2.3s**, then pty released (EIO @2.3s). Two-stage daemon observed: stage-1 (inherits pty) dies ~2.3s; stage-2 (stdio→/dev/null) persists to serve selection |
| `sh -c "echo hi \| wl-copy -n >/dev/null 2>&1"` | **EIO @0.5s** — redirecting the wl-copy stage's stdio prevents the daemon from ever touching the pty |
| `timeout 4 sh -c 'echo hi \| wl-copy -n -f'` | exits immediately (fg mode), but selection dies with the client → useless for persistence |

So under a bare pty the hold is **~2.3s, not infinite**. Under real kitty the user observes an indefinite hang — the remaining unknown is why the daemon's pty release behaves differently inside kitty (kitty's own pty handling / its `close_on_child_death = no` logic seeing "processes still using the terminal").

## Candidate fixes (not yet chosen)
1. **`wl-copy -n >/dev/null 2>&1`** in the pipeline — proven to release the pty immediately (EIO @0.5s). Clipboard still works (daemon survives with /dev/null stdio). Minimal change to the `z` exec_cmd.
2. **`--override close_on_child_death=yes`** on the kitty launch — closes the window as soon as the child (bash) exits regardless of lingering pty holders. Surgical per-launch; global kitty.conf setting would kill bg-job terminals.
3. `--foreground` — rejected: kills the selection (no compositor caching).

## Resolution (2026-08-28, session 2)

### Open question #1 — WHY indefinite under kitty: RESOLVED (it's not kitty at all)
Live `/proc` inspection of a stuck daemon (kitty window `sh -c "echo hi | wl-copy -n"`, stuck >38s) showed:

```
fd0 -> /dev/null
fd1 -> /dev/null
fd2 -> /dev/pts/3   <-- stderr still on the pty slave
fd3 -> wayland socket
fd4 -> /tmp/wl-copy-buffer-XXXX/stdin (deleted)
```

Source (bugaevc/wl-clipboard v2.3.0, `src/wl-copy.c:55-90`, `did_set_selection_callback`) explains it exactly — the detach code **only redirects fd 0 and 1**:

```c
int devnull = open("/dev/null", O_RDWR);
dup2(devnull, STDOUT_FILENO);
dup2(devnull, STDIN_FILENO);
...
fork(); if (parent) exit(0);
```

**stderr (fd 2) is never redirected**, so the daemon inherits the pty slave on fd2 and holds it for the daemon's entire lifetime. The daemon only exits via `cancelled_callback`/`pasted_callback` (`exit(0)`) — i.e. when it loses the selection or serves a paste-once copy.

Re-ran the pty harness with /proc fd tracking: **bare `wl-copy -n` holds the pty indefinitely too (no EIO within 15s)** — identical to kitty. The earlier "EIO @2.3s" row was an artifact: in that run the daemon died early because a *competing wl-copy took over the selection* (cancelled → exit → pty released). Corroborated accidentally: the stuck repro window auto-closed a few minutes later, the moment the harness's next `wl-copy` seized the selection and the old daemon exited.

So: single mechanism, no kitty-specific behavior. kitty simply refuses to close a window whose pty is still referenced by any process.

### Open question #2 — is fix #1 sufficient: YES
Verified in real kitty: `kitty bash -c 'echo hi2 | wl-copy -n >/dev/null 2>&1'`
- window closed within ~1s (no lingering)
- clipboard intact: `wl-paste -n` → `hi2` (daemon survives with /dev/null stdio)

`--override close_on_child_death=yes` (fix #2) is therefore **not needed**.

## Candidate fixes (final)
1. **`wl-copy -n >/dev/null 2>&1`** in the pipeline — **CHOSEN**. Verified in-kitty; clipboard persists; no kitty config changes.
2. `--override close_on_child_death=yes` — no longer needed.
3. `--foreground` — rejected: kills the selection (no compositor caching).

(Upstream wl-clipboard has the same bug in principle: any daemonized `wl-copy` whose stderr points at a terminal pins that terminal. Upstream fix would be to `dup2(devnull, STDERR_FILENO)` too. Not filed.)

## Done
- `z` exec_cmd fixed in `.config/hypr/submap-utils.lua`: `wl-copy -n >/dev/null 2>&1`, with explanatory comment. Verified end-to-end with the real pipeline shape (`zoxide query -l | … | wl-copy -n >/dev/null 2>&1` in a kitty-float-z window): window closes immediately, clipboard gets the selected path.
- Takes effect after Hyprland reload (SUPER+Q).