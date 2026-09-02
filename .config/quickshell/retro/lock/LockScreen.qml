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

    property bool pendingSessionLock: false

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

    function queueSessionLock() {
        root.pendingSessionLock = true;
        stabilizeTimer.restart();
        if (!pendingTimer.running)
            pendingTimer.start();
    }

    function requestSessionLock() {
        if (!Lock.locked || sessionLock.locked)
            return;
        if (stabilizeTimer.running)
            return;
        if (root.realScreenCount() === 0) {
            if (!root.pendingSessionLock)
                Lock.logEvent("lock-pending: no-real-screen");
            root.pendingSessionLock = true;
            if (!pendingTimer.running)
                pendingTimer.start();
            return;
        }
        root.pendingSessionLock = false;
        pendingTimer.stop();
        sessionLock.locked = true;
    }

    function releaseSessionLock() {
        root.pendingSessionLock = false;
        stabilizeTimer.stop();
        pendingTimer.stop();
        sessionLock.locked = false;
    }

    Connections {
        target: Lock

        function onLockedChanged() {
            if (Lock.locked)
                root.queueSessionLock();
            else
                root.releaseSessionLock();
        }
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (Lock.locked && !sessionLock.locked)
                root.queueSessionLock();
        }
    }

    // Debounce for hotplug: outputs come and go in bursts.
    Timer {
        id: stabilizeTimer

        interval: 500
        onTriggered: root.requestSessionLock()
    }

    Timer {
        id: pendingTimer

        interval: 100
        repeat: true
        onTriggered: root.requestSessionLock()
    }

    WlSessionLock {
        id: sessionLock

        locked: false

        onSecureStateChanged: {
            Lock.secure = sessionLock.secure;
            Lock.logEvent("secure=" + sessionLock.secure);
            if (sessionLock.secure) {
                root.pendingSessionLock = false;
                stabilizeTimer.stop();
                pendingTimer.stop();
            }
        }

        onLockStateChanged: {
            Lock.logEvent("session-locked=" + sessionLock.locked);
            if (sessionLock.locked) {
                root.pendingSessionLock = false;
                stabilizeTimer.stop();
                pendingTimer.stop();
            } else if (Lock.locked) {
                Lock.sessionDropped();
            }
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
