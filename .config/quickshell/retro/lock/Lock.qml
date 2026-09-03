pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// The lock: state, authentication and the side effects around it. The
// Wayland session lock itself and the surfaces live in LockScreen.qml,
// which watches `locked` here; the module drawn on each output is
// LcdLockView.qml, which only reads this and calls back into it.
//
// Two jobs beyond the lock itself:
//   * blank the screens after a short while on the lock screen, and wake
//     them on any input, with a wall-clock guard so a countdown frozen by
//     suspend does not blank the freshly resumed unlock screen;
//   * answer `qs -c retro ipc call lock ...` for the power submap and for
//     hypridle (hypr/hypridle.conf), which asks for the lock on idle, on
//     `loginctl lock-session` and before suspend. Whether the lock is secure
//     hypridle learns from the compositor, not from here.
//
// The password never leaves this file: it is held only until PAM answers,
// cleared on every terminal state, never logged and never taken over IPC.
Singleton {
    id: root

    // A lock has been asked for and not yet released. The session lock
    // follows this; `secure` reports back once the compositor has it.
    property bool locked: false
    // Mirrors WlSessionLock.secure, set by LockScreen.
    property bool secure: false
    // PAM has the password and has not answered yet.
    property bool checking: false
    // The last answer was no; cleared by the blink timer or by typing.
    property bool denied: false
    property int failedAttempts: 0
    // The module shown in an ordinary overlay window, input live, so PAM and
    // the look can be tried without taking a real session lock.
    property bool previewVisible: false
    // The shell turned the displays off; the next input has to turn them on.
    // Hyprland lights them on its own for key presses and mouse moves
    // (misc:key_press_enables_dpms), so this only gates the explicit dispatch.
    property bool blanked: false

    property string hostname: ""
    property string lastEvent: "init"
    property string lastEventAt: ""

    // What the view types into. Kept here so every surface shows the same
    // cells whichever output has keyboard focus.
    property string password: ""
    property string pendingPassword: ""

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
    readonly property bool inputActive: root.locked || root.previewVisible
    readonly property int blankAfterMs: 10000

    function logEvent(event) {
        root.lastEvent = event;
        root.lastEventAt = new Date().toISOString();
        console.log("retro lock " + root.lastEventAt + " " + event);
    }

    function resetAuth() {
        root.password = "";
        root.pendingPassword = "";
        root.checking = false;
        root.denied = false;
        root.failedAttempts = 0;
        deniedTimer.stop();
        if (pam.active)
            pam.abort();
    }

    function lock() {
        if (root.locked)
            return true;
        root.previewVisible = false;
        root.resetAuth();
        root.locked = true;
        root.armBlank();
        root.logEvent("lock-requested");
        return true;
    }

    // Success: drop the lock at once.
    function unlock() {
        if (!root.locked && !root.previewVisible)
            return;
        root.checking = false;
        root.password = "";
        root.pendingPassword = "";
        if (root.previewVisible) {
            root.previewVisible = false;
            root.resetAuth();
            root.logEvent("preview-unlocked");
            return;
        }
        root.locked = false;
        root.secure = false;
        blankTimer.stop();
        root.resetAuth();
        root.logEvent("unlocked");
        // `blanked` can be stale across a suspend, so always light up here;
        // the dispatch is skipped anyway when every display is already on.
        root.blanked = true;
        root.wake();
    }

    // The compositor let go of the lock without us asking (the surface
    // died, or something else unlocked); do not keep pretending.
    function sessionDropped() {
        if (!root.locked)
            return;
        root.logEvent("session-dropped");
        root.locked = false;
        root.secure = false;
        blankTimer.stop();
        root.resetAuth();
        root.wake();
    }

    function submit(value) {
        var password = String(value || "");
        if (!root.inputActive || root.checking || password.length === 0)
            return;
        root.wake();
        root.pendingPassword = password;
        root.password = "";
        root.denied = false;
        deniedTimer.stop();
        root.checking = true;
        blankTimer.stop();
        if (!pam.start()) {
            root.fail();
            return;
        }
        Qt.callLater(root.respondToPam);
    }

    function respondToPam() {
        if (!root.checking || !pam.active || !pam.responseRequired)
            return;
        pam.respond(root.pendingPassword);
    }

    function fail() {
        root.checking = false;
        root.pendingPassword = "";
        root.password = "";
        if (!root.inputActive)
            return;
        root.failedAttempts += 1;
        root.denied = true;
        deniedTimer.restart();
        root.logEvent("denied " + root.failedAttempts);
        root.wake();
    }

    function clearDenied() {
        root.denied = false;
        deniedTimer.stop();
    }

    // Any input on the lock screen: lights the displays if we turned them off
    // and starts the blank countdown over.
    function wake() {
        if (root.blanked && !wakeProcess.running) {
            root.blanked = false;
            wakeProcess.running = true;
        }
        if (root.locked)
            root.armBlank();
    }

    function armBlank() {
        blankTimer.armedAt = Date.now();
        blankTimer.restart();
    }

    function blank() {
        if (blankProcess.running)
            return;
        root.blanked = true;
        blankProcess.running = true;
    }

    function status() {
        return JSON.stringify({
            locked: root.locked,
            secure: root.secure,
            checking: root.checking,
            failedAttempts: root.failedAttempts,
            preview: root.previewVisible,
            lastEvent: root.lastEvent,
            lastEventAt: root.lastEventAt
        });
    }

    PamContext {
        id: pam

        // A two-line stack of our own (lock/pam.d/retro-lock) rather than the
        // system `login` one: Arch's system-auth carries pam_faillock, and
        // three typos on a lock screen should not lock the account out.
        config: "retro-lock"
        configDirectory: Quickshell.shellPath("lock/pam.d")
        user: root.userName

        onResponseRequiredChanged: root.respondToPam()
        onPamMessage: root.respondToPam()

        onCompleted: (result) => {
            root.pendingPassword = "";
            if (!root.checking)
                return;
            if (result === PamResult.Success)
                root.unlock();
            else
                root.fail();
        }

        onError: (error) => {
            root.logEvent("pam-error " + error);
            root.fail();
        }
    }

    // How long the denied state shows: three blinks at the toast's cadence.
    Timer {
        id: deniedTimer

        interval: 1500
        onTriggered: root.denied = false
    }

    Timer {
        id: blankTimer

        interval: root.blankAfterMs
        property double armedAt: 0

        onTriggered: {
            // A countdown frozen by suspend fires right after resume, which
            // would blank the just-woken unlock screen under the user. The
            // wall clock shows the gap: take a fresh run-up instead.
            if (Date.now() - armedAt > interval + 2000) {
                root.armBlank();
                return;
            }
            if (root.locked && !root.checking)
                root.blank();
        }
    }

    onCheckingChanged: {
        if (!root.locked)
            return;
        if (root.checking)
            blankTimer.stop();
        else
            root.armBlank();
    }

    Process {
        id: blankProcess

        command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })' >/dev/null 2>&1"]
    }

    Process {
        id: wakeProcess

        // Skip the dispatch when every display is already lit: a redundant
        // DPMS enable right after resume forces another modeset, which
        // blanks the panel for a beat.
        command: ["bash", "-c", "hyprctl monitors -j 2>/dev/null | jq -e '[.[] | select(.disabled == false)] | length > 0 and all(.dpmsStatus)' >/dev/null 2>&1 && exit 0; hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })' >/dev/null 2>&1"]
    }

    FileView {
        path: "/etc/hostname"
        printErrors: false
        onLoaded: root.hostname = text().trim()
    }

    IpcHandler {
        target: "lock"

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml), so the names
        // exposed here steer clear of them. There is deliberately no
        // unlock: the only way out is the password. `lock` is what hypridle
        // calls; it is idempotent, so repeated requests are harmless.
        function lock(): string {
            return root.lock() ? "ok" : "failed";
        }

        function isLocked(): string {
            return root.locked ? "true" : "false";
        }

        function status(): string {
            return root.status();
        }

        function preview(): string {
            if (root.locked)
                return "locked";
            root.resetAuth();
            root.previewVisible = true;
            return "ok";
        }

        function hidePreview(): string {
            root.previewVisible = false;
            root.resetAuth();
            return "ok";
        }
    }
}
