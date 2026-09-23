pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../services"

// The server, topics and token are read from ntfy.json under the state dir
// and never from the checkout; they still show in curl's /proc cmdline.
Singleton {
    id: root

    readonly property string server: String(config.server || "").replace(/\/+$/, "")
    readonly property var topics: root.cleanTopics(config.topics)
    readonly property string token: String(config.token || "")
    readonly property string endpoint: root.server !== "" && root.topics.length > 0 ? root.server + "/" + root.topics.join(",") : ""
    readonly property bool configured: root.endpoint !== ""
    property bool loaded: false

    property bool connected: false
    property string error: ""
    property double openedAt: 0
    property string since: "all"
    property double newest: 0
    property var seen: []

    function cleanTopics(raw) {
        var list = JSON.parse(JSON.stringify(raw || []));
        var out = [];
        for (var i = 0; i < list.length; i++) {
            var topic = String(list[i]).trim();
            if (topic !== "" && out.indexOf(topic) < 0)
                out.push(topic);
        }
        return out;
    }

    onEndpointChanged: root.reset()
    onTokenChanged: root.reset()

    function reset() {
        root.since = "all";
        root.newest = 0;
        root.seen = [];
        root.error = "";
        root.connected = false;
        if (stream.running)
            stream.signal(15);
    }

    function handle(line) {
        silence.restart();
        var event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (event.http !== undefined && event.error !== undefined) {
            root.error = String(event.error);
            console.warn("ntfy: " + line);
            return;
        }
        if (event.event === "open") {
            // The server's own clock on both sides of the backfill test, so
            // local skew cannot make backlog look live.
            root.openedAt = event.time > 0 ? event.time : Math.floor(Date.now() / 1000) - 5;
            root.connected = true;
            root.error = "";
        } else if (event.event === "message") {
            root.ingest(event);
        }
    }

    function ingest(event) {
        var id = String(event.id || "");
        if (id === "" || root.seen.indexOf(id) >= 0)
            return;
        root.seen = [id].concat(root.seen).slice(0, 200);
        var time = Number(event.time) || 0;
        root.newest = Math.max(root.newest, time);
        if (time < root.openedAt)
            return;
        var priority = Math.min(5, Math.max(1, Number(event.priority) || 3));
        var click = String(event.click || "");
        // Always a default action: without one invoke() falls back to
        // focusApp, whose substring match on a topic name like "main" can
        // land on an unrelated window.
        Notifications.post({
            appName: String(event.topic || ""),
            desktopEntry: "ntfy",
            summary: String(event.title || ""),
            body: String(event.message || ""),
            urgency: priority <= 2 ? 0 : priority === 3 ? 1 : 2,
            bypassDnd: priority >= 5,
            actions: [{
                    identifier: "default",
                    invoke: function () {
                        if (click !== "")
                            Quickshell.execDetached(["xdg-open", click]);
                    }
                }]
        });
    }

    JsonStore {
        dir: Settings.stateDir
        name: "ntfy.json"
        onReady: root.loaded = true

        JsonAdapter { // qmllint disable unresolved-type
            id: config

            property string server: ""
            property var topics: []
            property string token: ""
        }
    }

    Daemon {
        id: stream

        wanted: root.loaded && root.configured
        delay: 10000
        // Offline, curl exits within a second every time; that is not a
        // broken command, so it is never given up on.
        maxShortExits: 1000000
        command: {
            var c = ["curl", "-sN", "--connect-timeout", "10"];
            if (root.token !== "")
                c.push("-H", "Authorization: Bearer " + root.token);
            c.push(root.endpoint + "/json?since=" + root.since);
            return c;
        }

        stdout: SplitParser {
            onRead: (line) => root.handle(line)
        }

        stderr: SplitParser {
            onRead: (line) => console.warn("ntfy: " + line)
        }

        onStarted: silence.restart()

        // The cursor moves only here, between one curl and the next: a
        // timestamp rather than the newest id, which may have left the
        // server's cache by the time this reconnects.
        onExited: { // qmllint disable signal-handler-parameters
            silence.stop();
            root.connected = false;
            root.since = root.newest > 0 ? String(root.newest - 60) : "all";
        }
    }

    // Keepalives come every 45s; a stream quiet past that has died without
    // curl noticing.
    Timer {
        id: silence

        interval: 120000
        onTriggered: stream.signal(15)
    }

    IpcHandler {
        target: "ntfy"

        function status(): string {
            return "configured=" + (root.configured ? "yes" : "no") + " topics=" + root.topics.length + " connected=" + (root.connected ? "yes" : "no") + " pid=" + (stream.running ? stream.processId : 0) + " since=" + root.since + (root.error !== "" ? " error=" + root.error : "");
        }

        function reconnect(): void {
            root.reset();
        }
    }
}
