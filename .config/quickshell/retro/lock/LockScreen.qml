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

    // Runs from retryTimer only, so a lock request is always debounced and a
    // request that finds no output simply waits for the next tick.
    function requestSessionLock() {
        if (!Lock.locked || sessionLock.locked)
            return;
        if (root.realScreenCount() === 0) {
            Lock.logEvent("lock-pending: no-real-screen");
            retryTimer.restart();
            return;
        }
        sessionLock.locked = true;
    }

    Connections {
        target: Lock

        function onLockedChanged() {
            if (Lock.locked) {
                retryTimer.restart();
            } else {
                retryTimer.stop();
                sessionLock.locked = false;
            }
        }
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (Lock.locked && !sessionLock.locked)
                retryTimer.restart();
        }
    }

    // One timer for both jobs: debounce hotplug bursts, and retry while there
    // is no real output to draw on.
    Timer {
        id: retryTimer

        interval: 500
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
