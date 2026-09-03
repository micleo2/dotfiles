pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

// The launcher: rofi's two jobs, `-show drun` and `-dmenu`, as one LCD
// module. State and both sources live here; LauncherOverlay.qml draws it.
//
// Apps mode lists the desktop entries Quickshell already parses, ranked by
// how often each has been launched from here (launcher.json beside
// settings.json), and runs the chosen one through gtk-launch, the way the
// apps submap does.
//
// Dmenu mode is driven by scripts/retro-launcher: the script writes its
// stdin to a file, makes a FIFO beside it, calls `launcher dmenu <dir>
// <prompt>` and blocks reading the FIFO. The chosen line goes back through
// the FIFO untouched (cliphist wants its own line back, tab and all); a
// cancel sends an empty line and the script exits 1, rofi's code for it.
//
// Matching is the real `fzf --filter`, not a scorer of our own: every item
// goes in as `index<TAB>text` with the index kept out of the match by
// --nth, and the indices that come back are the ranking. An empty query is
// the source's own order (stdin order for dmenu, launch count for apps),
// which is what lets cliphist's recency and zoxide's ranking show through.
Singleton {
    id: root

    property bool shown: false
    // The output to show on, by name; chosen when the window opens.
    property string screenName: ""
    // "apps" or "dmenu".
    property string mode: "apps"
    property string prompt: ""
    // The dmenu call being served: its directory, or "" for none.
    property string dmenuDir: ""

    // Everything on offer: {text, detail, icon, id, line, search}. `text`
    // and `detail` are what a row shows, `search` is what fzf sees, `line`
    // is what dmenu hands back, `id` is the desktop entry to launch.
    property var items: []
    property string query: ""
    // Indices into items, best first.
    property var matches: []
    property int selected: 0
    // A match run is pending or under way.
    readonly property bool busy: matchTimer.running || matcher.running
    // The query the running matcher answers.
    property string matchFor: ""

    // Desktop entry id -> launches from here. Owned here and mirrored to
    // the store: a JsonAdapter property read straight back after assignment
    // still returns the old value.
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

    // Closing answers an open dmenu with nothing, so the script exits 1.
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
        // Matches index into items, so they go first or a row would look
        // up an index the new list does not have.
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

    // Every index, in source order.
    function everything() {
        var out = [];
        for (var i = 0; i < root.items.length; i++)
            out.push(i);
        return out;
    }

    readonly property var current: root.matches.length > 0 && root.selected < root.matches.length ? root.items[root.matches[root.selected]] : null

    // Enter: the selected item.
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

    // Shift+Enter: the typed text itself, rofi's custom entry. Apps have no
    // use for it, so it is a plain accept there.
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

    // The one write into the FIFO the script is blocked on. Its reader is
    // already there, so the open never blocks, but the write is detached
    // anyway: nothing of the shell waits on the pipe.
    function answer(line) {
        if (root.dmenuDir === "")
            return;
        var fifo = root.dmenuDir + "/out";
        root.dmenuDir = "";
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "_", line, fifo]);
    }

    // The desktop entries, most launched first, then by name.
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

    // What fzf reads: one item per line, its index in front and kept out
    // of the match. Newlines and tabs in the text would break the framing.
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

    // A beat after the query stops changing, so a fast typist runs one fzf
    // rather than one per key.
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
            // Closes stdin so fzf sees the end of its input.
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
            // The query moved on while fzf ran: answer the new one.
            if (root.query !== root.matchFor)
                root.runMatch();
        }
    }

    // The dmenu lines. cat rather than a FileView: the file is read once,
    // on a call, and never watched.
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

    // Mirror to disk, once per event-loop turn however many changes.
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
        // The adapter hands back a QVariantMap; a round trip through JSON
        // makes a plain object.
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
        // Only ever read at startup; writes go through writeStore().
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
