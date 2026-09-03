import QtQuick
import Quickshell.Io

// External monitors over DDC/CI, via ddcutil.
//
// One bus per connector, mapped from `ddcutil detect`, and the one that is
// driven is whichever `output` (the focused monitor's connector) names. The
// previous implementation took the first bus detect listed, which on a
// two-monitor desktop meant every write went to the HDMI monitor — including
// while it was powered off and refusing DDC — no matter which one was in use.
// Availability means "ddcutil found a display on the focused output", so a
// laptop panel or a DDC-less monitor falls through to the backlight backend.
Item {
    id: root

    // Connector name of the monitor to drive, e.g. "DP-1"; "" when unknown.
    property string output: ""

    readonly property bool available: root.bus >= 0
    property bool probed: false

    // connector name -> i2c bus number, as detect reported them.
    property var buses: ({})
    readonly property int bus: {
        var b = root.buses[root.output];
        if (b !== undefined)
            return b;
        // No focused output known (e.g. not running under Hyprland): keep the
        // old single-monitor behaviour and take whatever was found first.
        if (root.output === "") {
            for (var name in root.buses)
                return root.buses[name];
        }
        return -1;
    }

    // Last reading per bus, so switching focus back to a monitor shows its
    // level immediately instead of after another ~0.5s DDC round trip.
    property var readings: ({})

    // VCP 10's maximum is per-monitor and is frequently not 100.
    property int maxValue: 100
    property int rawValue: 0

    readonly property int percent: root.maxValue > 0 ? Math.round(root.rawValue / root.maxValue * 100) : 0

    onBusChanged: {
        var cached = root.readings[root.bus];
        if (cached) {
            root.rawValue = cached.raw;
            root.maxValue = cached.max;
        }
        root.refresh();
    }

    function apply(value) {
        if (!root.available)
            return;
        var clamped = Math.max(0, Math.min(100, value));
        root.rawValue = Math.round(clamped / 100 * root.maxValue);
        root.readings[root.bus] = { raw: root.rawValue, max: root.maxValue };
        writeDebounce.bus = root.bus;
        writeDebounce.target = root.rawValue;
        writeDebounce.restart();
    }

    function refresh() {
        if (!root.available)
            return;
        if (reader.running) {
            // Focus moved while a read was in flight; go again once it lands.
            reader.pending = true;
            return;
        }
        reader.forBus = root.bus;
        reader.running = true;
    }

    function probe() {
        if (!prober.running)
            prober.running = true;
    }

    Process {
        id: prober

        // `command -v` first so a machine without ddcutil never tries to launch
        // it: Quickshell logs a warning for a binary it cannot find, and the old
        // implementation produced one on every start of this laptop.
        // Output is one "<connector> <bus>" line per display, e.g. "DP-1 3".
        running: true
        command: ["bash", "-c", "command -v ddcutil >/dev/null 2>&1 && ddcutil detect --brief 2>/dev/null | awk '/I2C bus:/ { b = $3; sub(\"/dev/i2c-\", \"\", b) } /DRM connector:/ { c = $3; sub(/^card[0-9]+-/, \"\", c); if (c != \"\" && b != \"\") print c, b }' || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                var found = {};
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].trim().split(/\s+/);
                    if (parts.length === 2 && !isNaN(parseInt(parts[1], 10)))
                        found[parts[0]] = parseInt(parts[1], 10);
                }
                root.buses = found;
                root.probed = true;
                root.refresh();
            }
        }
    }

    Process {
        id: reader

        // Pinned when the read starts rather than bound to root.bus, so a focus
        // change mid-read cannot file the result under the wrong monitor.
        property int forBus: -1
        property bool pending: false

        command: ["ddcutil", "--bus", String(reader.forBus), "getvcp", "10", "--brief"]

        stdout: StdioCollector {
            onStreamFinished: {
                // "VCP 10 C <current> <max>"
                var parts = text.trim().split(/\s+/);
                if (parts.length >= 5) {
                    var raw = parseInt(parts[3], 10) || 0;
                    var max = parseInt(parts[4], 10) || 100;
                    root.readings[reader.forBus] = { raw: raw, max: max };
                    if (reader.forBus === root.bus) {
                        root.rawValue = raw;
                        root.maxValue = max;
                    }
                }
            }
        }

        onRunningChanged: {
            if (!reader.running && reader.pending) {
                reader.pending = false;
                root.refresh();
            }
        }
    }

    Timer {
        id: writeDebounce

        property int bus: -1
        property int target: 0

        // A DDC write takes the better part of a second and the monitor ignores
        // overlapping ones, so a held key has to coalesce into a single write
        // rather than queueing one per repeat.
        interval: 180
        onTriggered: {
            if (writer.running)
                writeDebounce.restart();
            else
                writer.running = true;
        }
    }

    Process {
        id: writer

        command: ["ddcutil", "--bus", String(writeDebounce.bus), "setvcp", "10", String(writeDebounce.target)]
    }
}
