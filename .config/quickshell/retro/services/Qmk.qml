pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// The QMK boards (the unicorne, the Svalboard) over their raw HID link.
//
// Nothing here touches USB: qmk-bridge.py beside this file owns the hidraw
// nodes and speaks JSON lines both ways, tagged with the board's name, so
// the shell needs no HID binding and the bridge can be tried from a
// terminal. The bridge keeps looking for boards while they are unplugged,
// and is restarted if it ever exits (Daemon), so `present` follows the cables.
// It runs only while the keyboard module is on (Modules): with the chip
// switched off nothing polls for boards, and the OSD and keymap viewer have
// no board to follow either.
//
// Every board's last state is kept in `boards`; the flat properties below
// mirror the *active* one, which is whichever board was typed on last (or
// the first to appear). The chip, the OSD and the viewer all read the
// flat properties, so they follow your hands from one board to the other.
//
// A board pushes its state whenever it changes (layers, RGB, caps word)
// and every key press and release; the shell only ever asks for a change
// and waits for the board to confirm it. The one exception is brightness,
// which is set optimistically so a slider drag reads right on the spot.
// The firmware side is ~/oss/keyboards/users/micleo2/host_link.c.
Singleton {
    id: root

    readonly property string bridgePath: Quickshell.shellDir + "/services/qmk/qmk-bridge.py"

    // Per-board state, by name: {layerState, defaultLayerState, layer, ...}.
    property var boards: ({})
    // Names of the boards present, in the order they appeared.
    property var present: []
    // The board the flat properties mirror; "" when none is present.
    property string active: ""
    property string error: ""

    readonly property bool anyPresent: root.present.length > 0

    // The active board, from its last STATE packet.
    property int layerState: 1
    property int defaultLayerState: 1
    property int layer: 0
    property int layerCount: 0
    property bool rgbOn: false
    property int mode: 0
    property int modeCount: 0
    property int hue: 0
    property int sat: 0
    property int val: 0
    property int maxBrightness: 255
    property bool capsWord: false
    property int os: 0

    // Keys held right now on the active board, as "row,col" strings.
    property var pressed: []

    readonly property int percent: root.maxBrightness > 0 ? Math.round(root.val / root.maxBrightness * 100) : 0
    property int step: 10
    // The OSD draws one segment per step, as Brightness does.
    readonly property int segments: Math.max(1, Math.round(100 / root.step))

    // The OSD listens for this. It fires on a deliberate change from the
    // shell only; a change made on the board moves `percent` quietly.
    signal brightnessChanged
    signal keyEvent(string board, int row, int col, bool down, int keycode)

    function send(command) {
        if (!bridge.running || root.active === "")
            return;
        command.board = root.active;
        bridge.write(JSON.stringify(command) + "\n");
    }

    function set(value) {
        if (!root.anyPresent)
            return;
        var p = Math.max(0, Math.min(100, Math.round(value)));
        root.val = Math.round(p / 100 * root.maxBrightness);
        root.send({
            cmd: "brightness",
            value: root.val
        });
        root.brightnessChanged();
    }

    function adjust(delta) {
        root.set(root.percent + delta);
    }

    function toggle() {
        root.send({
            cmd: "toggle"
        });
    }

    function setEnabled(on) {
        root.send({
            cmd: "enable",
            on: !!on
        });
    }

    function nextMode() {
        root.send({
            cmd: "mode",
            step: 1
        });
    }

    function prevMode() {
        root.send({
            cmd: "mode",
            step: -1
        });
    }

    function setMode(id) {
        root.send({
            cmd: "mode",
            id: id
        });
    }

    function toggleLayer(index) {
        root.send({
            cmd: "layer",
            toggle: index
        });
    }

    function clearLayers() {
        root.send({
            cmd: "layer",
            clear: true
        });
    }

    function layerActive(index) {
        return ((root.layerState | root.defaultLayerState) & (1 << index)) !== 0;
    }

    // Make a board the one the flat properties mirror.
    function activate(name) {
        if (name === root.active || !(name in root.boards))
            return;
        root.active = name;
        root.mirror();
    }

    function mirror() {
        var state = root.boards[root.active];
        if (!state)
            return;
        root.layerState = state.layerState;
        root.defaultLayerState = state.defaultLayerState;
        root.layer = state.layer;
        root.layerCount = state.layerCount;
        root.rgbOn = state.rgbOn;
        root.mode = state.mode;
        root.modeCount = state.modeCount;
        root.hue = state.hue;
        root.sat = state.sat;
        root.val = state.val;
        root.maxBrightness = state.maxBrightness;
        root.capsWord = state.capsWord;
        root.os = state.os;
        root.pressed = state.pressed;
    }

    function blank() {
        return {
            layerState: 1,
            defaultLayerState: 1,
            layer: 0,
            layerCount: 0,
            rgbOn: false,
            mode: 0,
            modeCount: 0,
            hue: 0,
            sat: 0,
            val: 0,
            maxBrightness: 255,
            capsWord: false,
            os: 0,
            pressed: []
        };
    }

    function handle(line) {
        var event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            console.warn("qmk: bridge said something that is not JSON: " + line);
            return;
        }
        var name = String(event.board || "");
        var all = root.boards;
        switch (event.event) {
        case "connected": {
            all[name] = root.blank();
            root.boards = all;
            if (root.present.indexOf(name) === -1)
                root.present = root.present.concat([name]);
            if (root.active === "")
                root.activate(name);
            break;
        }
        case "state": {
            var state = all[name] || root.blank();
            state.layerState = event.layers;
            state.defaultLayerState = event.defaultLayers;
            state.layer = event.layer;
            state.layerCount = event.layerCount;
            state.rgbOn = event.rgbOn;
            state.mode = event.mode;
            state.modeCount = event.modeCount;
            state.hue = event.h;
            state.sat = event.s;
            state.val = event.v;
            state.maxBrightness = event.max;
            state.capsWord = event.capsWord;
            state.os = event.os;
            all[name] = state;
            root.boards = all;
            if (root.present.indexOf(name) === -1)
                root.present = root.present.concat([name]);
            root.error = "";
            if (root.active === "")
                root.active = name;
            if (name === root.active)
                root.mirror();
            break;
        }
        case "key": {
            var board = all[name] || root.blank();
            var id = event.row + "," + event.col;
            var next = board.pressed.filter(function (k) {
                return k !== id;
            });
            if (event.pressed)
                next.push(id);
            board.pressed = next;
            all[name] = board;
            root.boards = all;
            // Typing on a board makes it the one the shell shows.
            if (name !== root.active)
                root.activate(name);
            else
                root.pressed = next;
            root.keyEvent(name, event.row, event.col, event.pressed, event.keycode);
            break;
        }
        case "disconnected": {
            delete all[name];
            root.boards = all;
            root.present = root.present.filter(function (b) {
                return b !== name;
            });
            if (name === root.active) {
                root.active = root.present.length > 0 ? root.present[0] : "";
                if (root.active !== "")
                    root.mirror();
                else
                    root.pressed = [];
            }
            break;
        }
        case "error":
            root.error = String(event.message || "");
            console.warn("qmk: " + (name !== "" ? name + ": " : "") + root.error);
            break;
        }
    }

    Daemon {
        id: bridge

        command: ["python3", root.bridgePath]
        wanted: Modules.on("keyboard")
        stdinEnabled: true

        stdout: SplitParser {
            onRead: (line) => root.handle(line)
        }

        stderr: SplitParser {
            onRead: (line) => console.warn("qmk-bridge: " + line)
        }

        // Process.exited carries a QProcess::ExitStatus that Quickshell does
        // not expose to QML, so qmllint cannot type the handler.
        onExited: { // qmllint disable signal-handler-parameters
            root.boards = ({});
            root.present = [];
            root.active = "";
            root.pressed = [];
        }
    }

    IpcHandler {
        target: "qmk"

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function up(): string {
            root.adjust(root.step);
            return root.percent + "%";
        }

        function down(): string {
            root.adjust(-root.step);
            return root.percent + "%";
        }

        function set(value: string): string {
            var parsed = parseInt(value, 10);
            if (isNaN(parsed))
                return "not a number: " + value;
            root.set(parsed);
            return root.percent + "%";
        }

        function toggle(): string {
            root.toggle();
            return root.rgbOn ? "off" : "on";
        }

        // "next" or "prev", or a mode number.
        function mode(which: string): string {
            var want = String(which || "next").toLowerCase();
            if (want === "next")
                root.nextMode();
            else if (want === "prev")
                root.prevMode();
            else if (/^\d+$/.test(want))
                root.setMode(parseInt(want, 10));
            else
                return "unknown mode " + which;
            return "mode " + root.mode;
        }

        // Toggle a layer by index, or "clear".
        function layer(which: string): string {
            var want = String(which || "").toLowerCase();
            if (want === "clear")
                root.clearLayers();
            else if (/^\d+$/.test(want))
                root.toggleLayer(parseInt(want, 10));
            else
                return "unknown layer " + which;
            return "layer " + root.layer;
        }

        // Make a board the active one by name, or list them.
        function board(name: string): string {
            var want = String(name || "");
            if (want === "")
                return root.present.length === 0 ? "no boards" : root.present.map(b => b === root.active ? b + "*" : b).join(" ");
            if (root.present.indexOf(want) === -1)
                return "no board " + want + " (have " + root.present.join(" ") + ")";
            root.activate(want);
            return want;
        }

        function status(): string {
            if (!root.anyPresent)
                return "no board" + (root.error !== "" ? " (" + root.error + ")" : "");
            return root.active + ": layer " + root.layer + " of " + root.layerCount + ", rgb " + (root.rgbOn ? "on" : "off") + " mode " + root.mode + " " + root.percent + "%" + (root.capsWord ? ", caps word" : "") + (root.present.length > 1 ? " (also " + root.present.filter(b => b !== root.active).join(" ") + ")" : "");
        }
    }
}
