pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// WireGuard tunnels, through NetworkManager.
//
// This is the one network feature that has to shell out: Quickshell's Networking
// module models wifi and wired devices only — its DeviceType enum is literally
// ["None", "Wifi", "Wired"] — and the NMSettings type it hands out has no
// QML-visible members, so there is no VPN surface to bind to.
//
// Raising and dropping a connection needs no privileges: NetworkManager's
// org.freedesktop.NetworkManager.network-control polkit action is "yes" for an
// active local session. Only the one-time import of the .conf needs root,
// because /etc/wireguard is root-only, and that stays a manual step.
Singleton {
    id: root

    // { uuid, name, active }
    property var connections: []
    property string error: ""

    // Set by the popup while it is on screen. Nothing here polls when nobody is
    // looking; there is no bar indicator that would need the state otherwise.
    property bool watching: false

    readonly property bool anyActive: {
        for (var i = 0; i < root.connections.length; i++) {
            if (root.connections[i].active)
                return true;
        }
        return false;
    }

    // While a toggle is in flight the row shows the requested state rather than
    // the stale one, and reconciles when nmcli exits.
    property string pendingUuid: ""

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }

    function toggle(connection) {
        if (!connection || toggler.running)
            return;
        root.error = "";
        root.pendingUuid = connection.uuid;
        toggler.command = ["nmcli", "connection", connection.active ? "down" : "up", "uuid", connection.uuid];
        toggler.running = true;
    }

    onWatchingChanged: {
        if (root.watching)
            root.refresh();
    }

    Timer {
        running: root.watching
        interval: 2000
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: lister

        // UUID, TYPE and STATE can never contain a colon, but a connection name
        // can — nmcli escapes those as "\:". Putting NAME last means the first
        // three splits are unambiguous and the remainder is the name, so no
        // unescaping is needed for the fields that matter.
        command: ["nmcli", "-t", "-f", "UUID,TYPE,STATE,NAME", "connection", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                var out = [];
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.trim() === "")
                        continue;
                    var parts = line.split(":");
                    if (parts.length < 4)
                        continue;
                    // NM calls OpenVPN and friends type "vpn"; a kernel
                    // WireGuard profile is its own type. Only the latter here.
                    if (parts[1] !== "wireguard")
                        continue;
                    out.push({
                        uuid: parts[0],
                        active: parts[2] === "activated",
                        name: parts.slice(3).join(":").replace(/\\:/g, ":")
                    });
                }
                root.connections = out;
                root.pendingUuid = "";
            }
        }
    }

    Process {
        id: toggler

        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }

        // Process.exited carries a QProcess::ExitStatus that Quickshell does
        // not expose to QML, so qmllint cannot type the handler.
        onExited: (exitCode) => { // qmllint disable signal-handler-parameters
            root.pendingUuid = "";
            // NM reports the connection as activated a beat after nmcli returns.
            settle.restart();
        }
    }

    Timer {
        id: settle

        interval: 400
        onTriggered: root.refresh()
    }
}
