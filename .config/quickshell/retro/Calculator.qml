pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The calculator. Nothing here does arithmetic: every evaluation is the
// real `qalc` binary, so whatever the CLI accepts (units, variables, `to`,
// `base 16`, `exact`, `help sin`) works the same way here, with the same
// output. Rendered by calc/CalcOverlay.qml.
//
// qalc is stateful (`x = 5` then `x * 2`) and a one-shot run is not, so the
// session's committed lines are replayed in front of every evaluation
// through `-f`, with a `clear` between them and the line being evaluated:
// `clear` prints one fixed escape sequence and nothing else, which marks
// where the current line's output starts. A one-shot run never writes
// qalc.cfg, so a half-typed `base 16` previewed on the way to something
// else cannot leak into the CLI's saved mode the way a piped session would.
//
// The console and the replayed history are mirrored to calc.json beside
// settings.json, so a config reload does not wipe the session.
Singleton {
    id: root

    property bool shown: false
    // The output to show on, by name; chosen when the window opens.
    property string screenName: ""

    // Committed lines in order, replayed before every evaluation.
    property var history: []
    // What the console shows: {id, input, lines, pending}.
    property var entries: []
    // Both are owned here and only mirrored to the store: a JsonAdapter
    // property read straight back after assignment still returns the old
    // value, which lost entries and left results unattached.
    property bool restored: false
    // Committed lines qalc will replay. Every line is a small parse, so a
    // long session stays quick; the cap keeps a very old one from dragging.
    readonly property int historyLimit: 1000
    // Console entries kept; the oldest go as new ones come. Every commit
    // rebuilds the console's rows, so this bounds that too.
    readonly property int entryLimit: 500

    // The line being typed, and qalc's answer to it as it stands.
    property string draft: ""
    property var preview: []
    // The draft the preview answers, so the same text is not re-run.
    property string previewFor: ""
    readonly property bool busy: evaluator.running || root.queue.length > 0

    property var queue: []
    property var current: null
    property int nextId: 0

    // What `clear` writes to a non-terminal.
    readonly property string marker: "\x1b[1;1H\x1b[2J"

    signal cleared
    signal committed

    function open() {
        var monitor = Hyprland.focusedMonitor;
        root.screenName = monitor && monitor.name ? monitor.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        root.shown = true;
    }

    function dismiss() {
        root.shown = false;
    }

    function toggle() {
        if (root.shown)
            root.dismiss();
        else
            root.open();
    }

    function clear() {
        root.entries = [];
        root.persist();
        root.cleared();
    }

    // Mirror to disk, once per event-loop turn however many changes.
    function persist() {
        Qt.callLater(root.writeStore);
    }

    function writeStore() {
        if (!root.restored)
            return;
        store.history = root.history;
        store.entries = root.entries;
        storeFile.writeAdapter();
    }

    // Enter: hand the line to qalc and move it into the console. With
    // `copy` (Ctrl+V), also put its result on the clipboard and close;
    // the result lands once qalc answers, whether or not the window is
    // still up. `exit`, `quit` and `clear` are the CLI's own commands and
    // are handled here rather than replayed: the first two would end the
    // replay early, the last is only the screen.
    function commit(copy) {
        var text = root.draft.trim();
        if (text === "") {
            if (copy) {
                root.copyLast();
                root.dismiss();
            }
            return;
        }
        root.draft = "";
        root.preview = [];
        root.previewFor = "";
        if (text === "exit" || text === "quit") {
            root.dismiss();
            return;
        }
        if (text === "clear") {
            root.clear();
            return;
        }

        var before = root.history.slice();
        root.history = before.concat([text]).slice(-root.historyLimit);

        var entry = {
            id: root.nextId++,
            input: text,
            lines: [],
            pending: true
        };
        root.entries = root.entries.concat([entry]).slice(-root.entryLimit);
        root.persist();
        root.committed();

        var previewed = text === previewCache.text && previewCache.lines !== null;
        if (previewed) {
            root.setLines(entry.id, previewCache.lines);
            if (copy)
                root.copyResult(previewCache.lines);
        } else {
            root.enqueue({
                kind: "commit",
                text: text,
                hist: before,
                id: entry.id,
                copy: copy
            });
        }
        previewCache.text = "";
        previewCache.lines = null;
        if (copy)
            root.dismiss();
    }

    // The preview that was on screen when Enter was pressed answers the
    // same line against the same history, so it is the committed result.
    QtObject {
        id: previewCache

        property string text: ""
        property var lines: null
    }

    function setLines(id, lines) {
        var next = root.entries.slice();
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                next[i] = {
                    id: id,
                    input: next[i].input,
                    lines: lines,
                    pending: false
                };
                root.entries = next;
                root.persist();
                return;
            }
        }
    }

    // qalc prints "expression = result" (or "≈"); the result is the part
    // the clipboard wants. Errors and warnings come on their own lines
    // before it and are skipped.
    function resultOf(lines) {
        for (var i = lines.length - 1; i >= 0; i--) {
            var line = lines[i];
            if (line === "" || /^(error|warning):/i.test(line))
                continue;
            var at = Math.max(line.lastIndexOf(" = "), line.lastIndexOf(" ≈ "));
            return (at >= 0 ? line.substring(at + 3) : line).trim();
        }
        return "";
    }

    // What the console and preview show of qalc's output: the "= result"
    // tail of each "expression = result" line (the expression is already on
    // the prompt row), other lines (help text) as they are. Errors and
    // warnings are kept for a committed line and dropped from a preview:
    // every half-typed expression is an error until it is finished.
    function display(lines, withErrors) {
        var out = [];
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (/^(error|warning):/i.test(line)) {
                if (withErrors)
                    out.push(line);
                continue;
            }
            var at = Math.max(line.lastIndexOf(" = "), line.lastIndexOf(" ≈ "));
            out.push(at >= 0 ? line.substring(at + 1) : line);
        }
        return out;
    }

    function copyResult(lines) {
        var text = root.resultOf(lines);
        // wl-copy forks a child that stays alive to serve pastes, so it must
        // not be a Process the shell would wait on (see Addresses.qml).
        if (text !== "")
            Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function copyLast() {
        for (var i = root.entries.length - 1; i >= 0; i--) {
            if (!root.entries[i].pending) {
                root.copyResult(root.entries[i].lines);
                return;
            }
        }
    }

    // Live preview: re-run the draft a beat after it stops changing.
    onDraftChanged: {
        var text = root.draft.trim();
        if (text === "") {
            previewTimer.stop();
            root.preview = [];
            root.previewFor = "";
            root.dropPreviews();
            return;
        }
        if (text === root.previewFor)
            return;
        previewTimer.restart();
    }

    Timer {
        id: previewTimer

        interval: 40
        onTriggered: root.enqueue({
            kind: "preview",
            text: root.draft.trim(),
            hist: root.history.slice()
        })
    }

    function dropPreviews() {
        root.queue = root.queue.filter(function (job) {
            return job.kind !== "preview";
        });
    }

    // One qalc at a time. Only the newest preview is worth running, so a
    // queued one is replaced; commits are never dropped.
    function enqueue(job) {
        if (job.kind === "preview")
            root.dropPreviews();
        root.queue = root.queue.concat([job]);
        root.pump();
    }

    function pump() {
        if (evaluator.running || root.queue.length === 0)
            return;
        var job = root.queue[0];
        root.queue = root.queue.slice(1);
        root.current = job;
        var script = job.hist.join("\n") + "\nclear\n" + job.text + "\n";
        // The replay goes in through a process substitution rather than a
        // file on disk: nothing to write, nothing to clean up. -m bounds a
        // runaway calculation (factorial(1e6)) instead of hanging the queue.
        evaluator.command = ["bash", "-c", "exec qalc -m 3000 -f <(printf '%s' \"$1\") </dev/null", "_", script];
        evaluator.running = true;
    }

    // Everything after the last marker is the current line's output. qalc
    // does not colour a pipe, but anything else escape-shaped is stripped
    // just in case. Blank lines at the ends go; inner ones (help text) stay.
    function parse(text) {
        var at = text.lastIndexOf(root.marker);
        var tail = at >= 0 ? text.substring(at + root.marker.length) : text;
        tail = tail.replace(/\x1b\[[0-9;]*[A-Za-z]/g, "");
        var lines = tail.split("\n").map(function (line) {
            return line.replace(/\s+$/, "");
        });
        while (lines.length > 0 && lines[lines.length - 1] === "")
            lines.pop();
        while (lines.length > 0 && lines[0] === "")
            lines.shift();
        return lines;
    }

    function finished(lines) {
        var job = root.current;
        root.current = null;
        if (!job)
            return;
        if (job.kind === "preview") {
            // Stale if the draft moved on while qalc was running.
            if (job.text === root.draft.trim()) {
                root.preview = lines;
                root.previewFor = job.text;
                previewCache.text = job.text;
                previewCache.lines = lines;
            }
        } else {
            root.setLines(job.id, lines);
            if (job.copy)
                root.copyResult(lines);
        }
        root.pump();
    }

    Process {
        id: evaluator

        stdout: StdioCollector {
            id: stdoutCollector
        }

        stderr: StdioCollector {
            id: stderrCollector
        }

        // Process.exited carries a QProcess::ExitStatus that Quickshell does
        // not expose to QML, so qmllint cannot type the handler.
        onExited: { // qmllint disable signal-handler-parameters
            var lines = root.parse(stdoutCollector.text);
            var errors = root.parse(stderrCollector.text);
            root.finished(errors.length > 0 ? lines.concat(errors) : lines);
        }
    }

    IpcHandler {
        target: "calc"

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function dismiss(): void {
            root.dismiss();
        }
    }

    Process {
        // FileView will not create intermediate directories.
        running: true
        command: ["mkdir", "-p", Settings.stateDir]
        onExited: storeFile.reload() // qmllint disable signal-handler-parameters
    }

    FileView {
        id: storeFile

        path: Settings.stateDir + "/calc.json"
        // Not watched: a commit writes twice in quick succession (the line,
        // then its result) and a reload racing the second write would put
        // the first back. The file is only ever read at startup.
        watchChanges: false
        printErrors: false

        // Writes go through writeStore() only. The adapter reports an update
        // while it is being built, before the file has loaded, and writing
        // its empty defaults then would race the load and wipe the session.
        onLoaded: root.restore()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                root.restore();
        }

        JsonAdapter { // qmllint disable unresolved-type
            id: store

            property var history: []
            property var entries: []
        }
    }

    // Adopt the file's session, once: the file is loaded again after the
    // directory is made sure of, and by then the user may have typed.
    // Entries that were still waiting on qalc when the shell went down have
    // no result and no job; run them again so the console is whole.
    function plainArray(value) {
        if (value === null || value === undefined)
            return [];
        var out = JSON.parse(JSON.stringify(value));
        return Array.isArray(out) ? out : [];
    }

    function restore() {
        if (root.restored)
            return;
        root.restored = true;
        // The adapter hands back QVariantList sequences, which stringify as
        // arrays but are not JS arrays (Array.isArray is false); a round trip
        // through JSON makes real ones.
        root.history = root.plainArray(store.history);
        var entries = root.plainArray(store.entries);
        root.entries = entries;
        var maxId = -1;
        for (var i = 0; i < entries.length; i++)
            maxId = Math.max(maxId, entries[i].id);
        root.nextId = maxId + 1;
        for (var j = 0; j < entries.length; j++) {
            if (!entries[j].pending)
                continue;
            var at = root.history.lastIndexOf(entries[j].input);
            root.enqueue({
                kind: "commit",
                text: entries[j].input,
                hist: at > 0 ? root.history.slice(0, at) : [],
                id: entries[j].id,
                copy: false
            });
        }
        root.persist();
    }
}
