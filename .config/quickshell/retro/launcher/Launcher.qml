pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

// rofi's `-show drun` and `-dmenu` as one LCD module. Dmenu mode is driven
// by scripts/retro-launcher over a file and a FIFO; matching is `fzf
// --filter`. Drawn by LauncherOverlay.qml.
Singleton {
    id: root

    property bool shown: false
    property string screenName: ""
    // "apps" or "dmenu".
    property string mode: "apps"
    property string prompt: ""
    // The dmenu call being served: its directory, or "" for none.
    property string dmenuDir: ""

    // {text, detail, icon, id, line, search}: `search` is what fzf sees,
    // `line` is what dmenu hands back.
    property var items: []
    property string query: ""
    // Indices into items, best first.
    property var matches: []
    property int selected: 0
    readonly property bool busy: matchTimer.running || matcher.running
    property string matchFor: ""

    // Desktop entry id -> launches. Owned here and mirrored to the store: a
    // JsonAdapter property read straight back after assignment is stale.
    property var counts: ({})
    property bool restored: false

    signal opened

    function open() {
        var monitor = Hyprland.focusedMonitor;
        root.screenName = monitor && monitor.name ? monitor.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        matchTimer.stop();
        root.query = "";
        root.matchFor = "";
        root.matches = root.everything();
        root.selected = 0;
        root.shown = true;
        root.opened();
    }

    function dismiss() {
        root.shown = false;
        root.answer("");
    }

    function apps() {
        if (root.shown && root.mode === "apps") {
            root.dismiss();
            return;
        }
        root.answer("");
        root.mode = "apps";
        root.prompt = "APPS";
        // Matches index into items, so they are cleared first.
        root.matches = [];
        root.items = root.appItems();
        root.open();
    }

    function toggle() {
        root.apps();
    }

    function dmenu(dir, prompt) {
        root.answer("");
        root.dmenuDir = dir;
        root.prompt = prompt;
        reader.command = ["cat", "--", dir + "/items"];
        reader.running = true;
    }

    function everything() {
        var out = [];
        for (var i = 0; i < root.items.length; i++)
            out.push(i);
        return out;
    }

    readonly property var current: root.matches.length > 0 && root.selected < root.matches.length ? root.items[root.matches[root.selected]] : null

    function accept() {
        var item = root.current;
        if (item === null)
            return;
        if (root.mode === "apps") {
            root.bump(item.id);
            Quickshell.execDetached(["gtk-launch", item.id]);
            root.dismiss();
        } else {
            root.answer(item.line);
            root.dismiss();
        }
    }

    // Shift+Enter: the typed text itself, rofi's custom entry.
    function acceptCustom() {
        if (root.mode === "apps") {
            root.accept();
            return;
        }
        root.answer(root.query);
        root.dismiss();
    }

    function select(index) {
        if (root.matches.length === 0)
            return;
        root.selected = Math.max(0, Math.min(root.matches.length - 1, index));
    }

    function move(delta) {
        root.select(root.selected + delta);
    }

    function answer(line) {
        if (root.dmenuDir === "")
            return;
        var fifo = root.dmenuDir + "/out";
        root.dmenuDir = "";
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "_", line, fifo]);
    }

    function appItems() {
        var entries = DesktopEntries.applications.values;
        var out = [];
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            if (!entry || entry.noDisplay)
                continue;
            var keywords = [];
            var raw = entry.keywords || [];
            for (var k = 0; k < raw.length; k++)
                keywords.push(raw[k]);
            var detail = entry.genericName || entry.comment || "";
            out.push({
                text: entry.name,
                detail: detail,
                icon: entry.icon || "",
                id: entry.id,
                line: "",
                count: root.counts[entry.id] || 0,
                search: [entry.name, detail, entry.comment || "", keywords.join(" ")].join(" ")
            });
        }
        out.sort(function (a, b) {
            if (a.count !== b.count)
                return b.count - a.count;
            return a.text.localeCompare(b.text);
        });
        return out;
    }

    function bump(id) {
        var next = {};
        for (var k in root.counts)
            next[k] = root.counts[k];
        next[id] = (next[id] || 0) + 1;
        root.counts = next;
        root.persist();
    }

    // `index<TAB>search`; --nth keeps the index out of the match.
    function feed() {
        var lines = [];
        for (var i = 0; i < root.items.length; i++)
            lines.push(i + "\t" + String(root.items[i].search).replace(/[\t\r\n]+/g, " "));
        return lines.join("\n") + "\n";
    }

    onQueryChanged: {
        var q = root.query;
        if (q === "") {
            matchTimer.stop();
            root.matchFor = "";
            root.matches = root.everything();
            root.selected = 0;
            return;
        }
        if (q === root.matchFor)
            return;
        matchTimer.restart();
    }

    Timer {
        id: matchTimer

        interval: 30
        onTriggered: root.runMatch()
    }

    function runMatch() {
        if (matcher.running)
            return;
        var q = root.query;
        if (q === "" || q === root.matchFor)
            return;
        root.matchFor = q;
        matcher.stdinEnabled = true;
        matcher.command = ["fzf", "--filter", q, "--delimiter", "\t", "--nth", "2..", "--tiebreak", "index"];
        matcher.running = true;
    }

    Process {
        id: matcher

        stdout: StdioCollector {
            id: matchOut
        }

        onStarted: {
            matcher.write(root.feed());
            // Closes stdin; fzf reads to EOF.
            matcher.stdinEnabled = false;
        }

        // Process.exited carries a QProcess::ExitStatus that Quickshell does
        // not expose to QML, so qmllint cannot type the handler.
        onExited: { // qmllint disable signal-handler-parameters
            var stale = root.matchFor !== root.query;
            if (!stale) {
                var lines = matchOut.text.split("\n");
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    var at = lines[i].indexOf("\t");
                    if (at <= 0)
                        continue;
                    var index = parseInt(lines[i].substring(0, at), 10);
                    if (!isNaN(index) && index >= 0 && index < root.items.length)
                        out.push(index);
                }
                root.matches = out;
                root.selected = 0;
            }
            if (root.query !== root.matchFor)
                root.runMatch();
        }
    }

    Process {
        id: reader

        stdout: StdioCollector {
            id: readerOut
        }

        onExited: { // qmllint disable signal-handler-parameters
            var text = readerOut.text;
            var lines = text.split("\n");
            if (lines.length > 0 && lines[lines.length - 1] === "")
                lines.pop();
            var out = [];
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i];
                out.push({
                    text: line.replace(/\t/g, "  "),
                    detail: "",
                    icon: "",
                    id: "",
                    line: line,
                    count: 0,
                    search: line
                });
            }
            root.mode = "dmenu";
            root.matches = [];
            root.items = out;
            root.open();
        }
    }

    IpcHandler {
        target: "launcher"

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function apps(): void {
            root.apps();
        }

        function toggle(): void {
            root.toggle();
        }

        function dmenu(dir: string, prompt: string): void {
            root.dmenu(dir, prompt);
        }

        function dismiss(): void {
            root.dismiss();
        }
    }

    function persist() {
        Qt.callLater(root.writeStore);
    }

    function writeStore() {
        if (!root.restored)
            return;
        store.counts = root.counts;
        storeFile.writeAdapter();
    }

    function restore() {
        if (root.restored)
            return;
        root.restored = true;
        // A JSON round trip turns the adapter's QVariantMap into a plain object.
        var raw = store.counts;
        var out = {};
        if (raw !== null && raw !== undefined) {
            var parsed = JSON.parse(JSON.stringify(raw));
            for (var k in parsed)
                out[k] = parsed[k];
        }
        root.counts = out;
    }

    Process {
        // FileView will not create intermediate directories.
        running: true
        command: ["mkdir", "-p", Settings.stateDir]
        onExited: storeFile.reload() // qmllint disable signal-handler-parameters
    }

    FileView {
        id: storeFile

        path: Settings.stateDir + "/launcher.json"
        watchChanges: false
        printErrors: false

        onLoaded: root.restore()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                root.restore();
        }

        JsonAdapter { // qmllint disable unresolved-type
            id: store

            property var counts: ({})
        }
    }
}
