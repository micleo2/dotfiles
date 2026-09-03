pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// The Wayland side of the lock: the ext-session-lock object, one surface
// per output, and the preview window. State lives in the Lock singleton;
// this only turns `Lock.locked` into a session lock and reports back.
//
// Taking the lock is deferred while the screen set is changing (a monitor
// being toggled, the machine resuming) and refused while there is no real
// output at all, because a lock taken over an empty screen set has nowhere
// to draw and Hyprland has crashed on exactly that. Both guards are from
// omarchy's locker.
//
// Started with RETRO_LOCK_ON_START=1 (hyprland.lua's session start, where
// greetd auto-login makes this the login screen) the shell locks itself on
// its first load, the way quickshell's own lockscreen example does. The
// flag below survives config reloads, so a save does not lock again, and a
// shell restarted by hand carries no such variable.
Scope {
    id: root

    function realScreenCount() {
        var screens = Quickshell.screens || [];
        var count = 0;
        for (var i = 0; i < screens.length; i++) {
            var s = screens[i];
            if (s && s.name && s.width > 0 && s.height > 0)
                count += 1;
        }
        return count;
    }

    // Takes the lock at once when there is a real output and the screen set
    // has been still for a moment; otherwise it is retried from the timers
    // below. Nothing debounces a plain request, so a lock at session start
    // lands as soon as the shell is up rather than a timer tick later.
    function requestSessionLock() {
        if (!Lock.locked || sessionLock.locked)
            return;
        if (stabilizeTimer.running)
            return;
        if (root.realScreenCount() === 0) {
            Lock.logEvent("lock-pending: no-real-screen");
            retryTimer.restart();
            return;
        }
        retryTimer.stop();
        sessionLock.locked = true;
    }

    Connections {
        target: Lock

        function onLockedChanged() {
            if (Lock.locked) {
                root.requestSessionLock();
            } else {
                stabilizeTimer.stop();
                retryTimer.stop();
                sessionLock.locked = false;
            }
        }
    }

    Connections {
        target: Quickshell

        // A monitor being toggled or the machine resuming: hold the lock
        // until the outputs have settled, then take it.
        function onScreensChanged() {
            if (Lock.locked && !sessionLock.locked)
                stabilizeTimer.restart();
        }
    }

    PersistentProperties {
        id: startup

        reloadableId: "lockStartup"
        property bool handled: false

        // Runs once the tree is built, on the first load and every reload.
        onLoaded: {
            if (startup.handled)
                return;
            startup.handled = true;
            if (Quickshell.env("RETRO_LOCK_ON_START") === "1") {
                Lock.logEvent("lock-on-start");
                Lock.lock();
            }
        }
    }

    // Debounces hotplug bursts; only ever armed by a screen-set change.
    Timer {
        id: stabilizeTimer

        interval: 500
        onTriggered: root.requestSessionLock()
    }

    // Retries while there is no real output to draw on.
    Timer {
        id: retryTimer

        interval: 100
        onTriggered: root.requestSessionLock()
    }

    WlSessionLock {
        id: sessionLock

        locked: false

        onSecureStateChanged: {
            Lock.secure = sessionLock.secure;
            Lock.logEvent("secure=" + sessionLock.secure);
        }

        onLockStateChanged: {
            Lock.logEvent("session-locked=" + sessionLock.locked);
            if (sessionLock.locked)
                retryTimer.stop();
            else if (Lock.locked)
                Lock.sessionDropped();
        }

        WlSessionLockSurface { // qmllint disable uncreatable-type
            color: Config.colors.outline

            LcdLockView {
                anchors.fill: parent
                inputEnabled: Lock.locked
            }
        }
    }

    // The same module in an ordinary overlay, input live, so the look and
    // the PAM stack can be tried without locking. Right-click, or Escape on
    // an empty field, closes it; so does a correct password.
    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: previewWindow

            required property var modelData

            visible: Lock.previewVisible
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-lock-preview"
            WlrLayershell.keyboardFocus: Lock.previewVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: Config.colors.outline

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            LcdLockView {
                anchors.fill: parent
                inputEnabled: Lock.previewVisible
                preview: true
            }
        }
    }
}
