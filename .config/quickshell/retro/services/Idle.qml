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

    // ------------------------------------------------------- who is awake --

    // The readout of what is holding the screen up. Polled slowly all the
    // time once the chip has claimed it, so the chip can show at a glance
    // that something else holds the screen, and faster while the popup is
    // looking.
    property bool polling: false
    property bool watching: false
    property var clients: []
    property var inhibits: []

    // Everything holding the screen up, one list: windows with a Wayland
    // idle inhibitor (games, video players), then logind inhibitors in block
    // mode. Delay-mode logind entries (rtkit, upower, hypridle) only postpone
    // sleep by a moment and hold nothing. The shell's own IdleInhibitor sits
    // on the bar's layer surface, so it is not a client; its logind lock is
    // what shows, relabelled as the chip.
    readonly property var inhibitors: {
        var out = [];
        var i;
        for (i = 0; i < root.clients.length; i++) {
            var c = root.clients[i];
            if (c.inhibitingIdle !== true)
                continue;
            var title = String(c.title || "").trim();
            var cls = String(c.class || "").trim();
            out.push({
                glyph: "web_asset",
                text: title !== "" ? title : cls,
                detail: title !== "" ? cls : ""
            });
        }
        for (i = 0; i < root.inhibits.length; i++) {
            var e = root.inhibits[i];
            var what = String(e.what || "");
            if (e.mode !== "block" || !/idle|sleep/.test(what))
                continue;
            if (e.who === "retro-shell") {
                out.push({
                    glyph: "coffee",
                    text: "Stay awake",
                    detail: "this chip"
                });
                continue;
            }
            var why = String(e.why || "").trim();
            out.push({
                glyph: "lock_open",
                text: String(e.who || e.comm || "?") + (why !== "" ? " - " + why : ""),
                detail: what
            });
        }
        return out;
    }

    // Holders other than the chip's own stay-awake, which has its own look.
    readonly property int others: {
        var n = 0;
        for (var i = 0; i < root.inhibitors.length; i++) {
            if (root.inhibitors[i].glyph !== "coffee")
                n++;
        }
        return n;
    }

    function refresh() {
        clientsProc.running = true;
        inhibitsProc.running = true;
    }

    // While stay-awake is forced here the chip is urgent whatever else
    // holds the screen, so the background poll has nothing to show and
    // stops; it starts again, with a fresh read, the moment it is released.
    readonly property bool pollingNow: root.watching || (root.polling && !root.stayAwake)

    onPollingNowChanged: {
        if (root.pollingNow)
            root.refresh();
    }

    Timer {
        running: root.pollingNow
        interval: root.watching ? 2000 : 5000
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: clientsProc

        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.clients = JSON.parse(text);
                } catch (e) {
                    root.clients = [];
                }
            }
        }
    }

    Process {
        id: inhibitsProc

        command: ["systemd-inhibit", "--list", "--json=short"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.inhibits = JSON.parse(text);
                } catch (e) {
                    root.inhibits = [];
                }
            }
        }
    }

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

        // The last readout, one entry per line; poll for a fresh one by
        // opening the popup, or by calling this twice a moment apart.
        function inhibitors(): string {
            root.refresh();
            var lines = [];
            for (var i = 0; i < root.inhibitors.length; i++)
                lines.push(root.inhibitors[i].text + " [" + root.inhibitors[i].detail + "]");
            return lines.length > 0 ? lines.join("\n") : "none";
        }
    }
}
