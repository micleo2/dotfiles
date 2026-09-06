pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."
import "../services"

// The keyboard layout viewer's state: which board and which of its layers
// is on show, and whether the window is up. The layouts come from
// <board>.json under Settings.stateDir/keymap, written by keymap-export.py
// (~/oss/keyboards/host, `make export` there) from each QMK keymap and
// listed in index.json; every file is watched, so re-running the exporter
// after a flash updates the viewer in place. Rendered by KeymapOverlay.
//
// While a board is talking (services/Qmk.qml) the viewer follows it: type
// on the Svalboard and it shows the Svalboard, hold NAV and it flips to
// NAV, let go and it flips back. The keys still work in between; the next
// change on a board takes over again.
Singleton {
    id: root

    property bool shown: false
    // The output to show on, by name; chosen when the window opens.
    property string screenName: ""

    // Every board in index.json: [{name, title}].
    property var boards: []
    // Parsed <board>.json by name, once loaded.
    property var cache: ({})
    // The board on show.
    property string board: ""
    // Position in the shown board's layer list (not the board's own layer
    // number; that is layers[index].index).
    property int index: 0
    // Follow the active board and its layer while one is present.
    property bool follow: true

    readonly property var data: root.cache[root.board] || null
    readonly property var layers: root.data ? root.data.layers : []
    readonly property real width: root.data ? Number(root.data.width) : 0
    readonly property real height: root.data ? Number(root.data.height) : 0
    readonly property string title: root.data ? String(root.data.title) : root.board
    readonly property bool loaded: root.layers.length > 0
    readonly property var current: root.loaded ? root.layers[Math.max(0, Math.min(root.index, root.layers.length - 1))] : null
    readonly property string layerName: root.current ? root.current.name : ""

    function open() {
        var monitor = Hyprland.focusedMonitor;
        root.screenName = monitor && monitor.name ? monitor.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        root.followBoard();
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

    // The layer entry of a board for the layer number the board reports,
    // or null; for the chip, which names whichever board is active.
    function layerFor(boardName, boardLayer) {
        var data = root.cache[boardName];
        if (!data)
            return null;
        for (var i = 0; i < data.layers.length; i++)
            if (Number(data.layers[i].index) === boardLayer)
                return data.layers[i];
        return null;
    }

    // Show a board by name. Returns the name, or "" if there is no such
    // board.
    function selectBoard(name) {
        var want = String(name).toLowerCase();
        for (var i = 0; i < root.boards.length; i++) {
            if (String(root.boards[i].name).toLowerCase() === want) {
                if (root.board !== root.boards[i].name) {
                    root.board = root.boards[i].name;
                    root.index = 0;
                }
                return root.board;
            }
        }
        return "";
    }

    function nextBoard() {
        if (root.boards.length < 2)
            return;
        for (var i = 0; i < root.boards.length; i++)
            if (root.boards[i].name === root.board)
                return root.selectBoard(root.boards[(i + 1) % root.boards.length].name);
        root.selectBoard(root.boards[0].name);
    }

    // By position, by name ("NAV", case-insensitive), or "next"/"prev".
    // Returns the name now shown, or "" if nothing matched.
    function select(which) {
        if (!root.loaded)
            return "";
        var n = root.layers.length;
        var at = -1;
        if (typeof which === "number") {
            at = which;
        } else {
            var want = String(which).trim().toLowerCase();
            if (want === "next")
                at = (root.index + 1) % n;
            else if (want === "prev")
                at = (root.index + n - 1) % n;
            else if (/^\d+$/.test(want))
                at = parseInt(want, 10);
            else
                for (var i = 0; i < n; i++)
                    if (String(root.layers[i].name).toLowerCase() === want || String(root.layers[i].title).toLowerCase() === want)
                        at = i;
        }
        if (at < 0 || at >= n)
            return "";
        root.index = at;
        return root.layers[at].name;
    }

    function next() {
        root.select("next");
    }

    function prev() {
        root.select("prev");
    }

    // Show the active board and the layer it is on. A layer the export
    // left out (a filler layer) leaves the shown one alone.
    function followBoard() {
        if (!root.follow || !Qmk.anyPresent || Qmk.active === "")
            return;
        if (root.cache[Qmk.active] && root.board !== Qmk.active) {
            root.board = Qmk.active;
            root.index = 0;
        }
        for (var i = 0; i < root.layers.length; i++) {
            if (Number(root.layers[i].index) === Qmk.layer) {
                root.index = i;
                return;
            }
        }
    }

    Connections {
        target: Qmk

        function onLayerChanged() {
            root.followBoard();
        }

        function onActiveChanged() {
            root.followBoard();
        }
    }

    function adopt(name, text) {
        var data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.warn("keymap: " + name + ".json is not JSON: " + e);
            return;
        }
        if (!data || !Array.isArray(data.layers))
            return;
        var next = {};
        for (var key in root.cache)
            next[key] = root.cache[key];
        next[name] = data;
        root.cache = next;
        if (root.board === "")
            root.board = name;
        if (name === root.board && root.index >= data.layers.length)
            root.index = 0;
    }

    function adoptIndex(text) {
        var data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.warn("keymap: index.json is not JSON: " + e);
            return;
        }
        if (!data || !Array.isArray(data.boards))
            return;
        root.boards = data.boards;
    }

    FileView {
        id: indexFile

        path: Settings.stateDir + "/keymap/index.json"
        watchChanges: true
        printErrors: true

        onFileChanged: indexFile.reload()
        onLoaded: root.adoptIndex(indexFile.text())
    }

    // One watched file per listed board.
    Instantiator {
        model: root.boards

        FileView {
            id: boardFile

            required property var modelData

            path: Settings.stateDir + "/keymap/" + modelData.name + ".json"
            watchChanges: true
            printErrors: true

            onFileChanged: boardFile.reload()
            onLoaded: root.adopt(boardFile.modelData.name, boardFile.text())
        }
    }

    IpcHandler {
        target: "keymap"

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

        // Show a layer by name, position, "next" or "prev"; opens the
        // window if it is down. Returns the layer now shown.
        function layer(which: string): string {
            var name = root.select(which);
            if (name === "")
                return "unknown layer " + which + " (have " + root.layers.map(l => l.name).join(" ") + ")";
            if (!root.shown)
                root.open();
            return name;
        }

        // Show a board by name, or "next"; opens the window if it is down.
        function board(which: string): string {
            var name = String(which || "next") === "next" ? (root.nextBoard(), root.board) : root.selectBoard(which);
            if (name === "")
                return "unknown board " + which + " (have " + root.boards.map(b => b.name).join(" ") + ")";
            if (!root.shown)
                root.open();
            return name;
        }

        function status(): string {
            if (!root.loaded)
                return "no keymap loaded for " + root.board + " from " + Settings.stateDir + "/keymap";
            return root.board + " " + root.layerName + (root.shown ? " shown" : " hidden") + " (boards: " + root.boards.map(b => b.name).join(" ") + ")";
        }
    }
}
