pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// "Stay awake", and the logind half of enforcing it.
//
// Two locks are needed because they cover different things:
//   * a Wayland idle-inhibit lock, held by IdleWidget because it has a surface
//     to attach one to, suppresses compositor-side idling. hypridle honours
//     it, so stay-awake also means no auto-lock (see hypr/hypridle.conf).
//   * a logind inhibitor blocks suspend and lid-close, which is what actually
//     puts this machine to sleep right now. This is the half that does work.
Singleton {
    id: root

    readonly property bool stayAwake: Settings.stayAwake

    function setStayAwake(value) {
        Settings.stayAwake = value;
    }

    function toggle() {
        root.setStayAwake(!root.stayAwake);
    }

    Process {
        // Quickshell kills the child when running goes false, which is what
        // releases the lock; `sleep infinity` just holds it open until then.
        running: root.stayAwake
        command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--who=retro-shell", "--why=Stay awake", "--mode=block", "sleep", "infinity"]
    }

    IpcHandler {
        target: "idle"

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml), so the names
        // exposed here steer clear of them.
        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.setStayAwake(true);
        }

        function disable(): void {
            root.setStayAwake(false);
        }

        function status(): string {
            return root.stayAwake ? "on" : "off";
        }
    }
}
