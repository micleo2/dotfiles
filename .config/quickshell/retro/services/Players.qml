pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Pairs a playback stream with the MPRIS player of the same application, so
// the volume popup can say what an app is playing. Neither side names the
// other: MPRIS has no notion of an audio stream and PipeWire none of D-Bus.
// What they share is ancestry. Chromium's stream belongs to its audio-service
// child while the MPRIS name is held by the browser process, so the stream's
// process is walked up through its parents until one owns a player's bus
// connection. A plain player such as mpv is its own one-step chain. Matching
// by name instead (omarchy's approach) cannot tell two Chromium processes
// apart, which is exactly the browser-plus-YouTube-app case here.
Singleton {
    id: root

    // Stream process id -> D-Bus name of the player that owns it.
    property var owners: ({})
    property var pids: []
    property bool watching: false
    property bool stale: false

    function match(pids) {
        root.pids = pids;
        root.refresh();
    }

    function refresh() {
        if (!root.watching || root.pids.length === 0)
            return;
        if (matcher.running) {
            root.stale = true;
            return;
        }
        matcher.command = ["sh", "-c", root.script, "match"].concat(root.pids.map(String));
        matcher.running = true;
    }

    function playerFor(pid) {
        var name = root.owners[pid];
        if (!name)
            return null;
        var players = Mpris.players ? Mpris.players.values : [];
        for (var i = 0; i < players.length; i++) {
            if (players[i].dbusName === name)
                return players[i];
        }
        return null;
    }

    onWatchingChanged: {
        if (root.watching)
            root.refresh();
        else
            root.owners = {};
    }

    Connections {
        target: Mpris.players

        function onValuesChanged() {
            root.refresh();
        }
    }

    // busctl's PID column is "-" for a name that is activatable but not
    // running (playerctld), which never lands inside a chain.
    readonly property string script: "
names=$(busctl --user list --no-legend 2>/dev/null | awk '$1 ~ /^org\\.mpris\\.MediaPlayer2\\./ { print $2, $1 }')
for pid in \"$@\"; do
    chain=' '
    p=$pid
    while [ \"$p\" -gt 1 ] 2>/dev/null; do
        chain=\"$chain$p \"
        p=$(awk '/^PPid:/ { print $2 }' /proc/$p/status 2>/dev/null)
        [ -n \"$p\" ] || break
    done
    printf '%s\\n' \"$names\" | awk -v chain=\"$chain\" -v pid=\"$pid\" 'index(chain, \" \" $1 \" \") { print pid, $2 }'
done
"

    Process {
        id: matcher

        stdout: StdioCollector {
            onStreamFinished: {
                var out = {};
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].trim().split(" ");
                    if (parts.length === 2)
                        out[parts[0]] = parts[1];
                }
                root.owners = out;
            }
        }

        onExited: (exitCode) => { // qmllint disable signal-handler-parameters
            if (root.stale) {
                root.stale = false;
                root.refresh();
            }
        }
    }
}
