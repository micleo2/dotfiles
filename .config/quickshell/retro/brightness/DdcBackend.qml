import QtQuick
import Quickshell.Io

// External monitors over DDC/CI, via ddcutil.
//
// The bus is detected rather than hardcoded — the previous implementation pinned
// `--bus 3`, which was only ever true of one machine's monitor. Availability
// means "ddcutil is installed *and* it actually found a display", so a machine
// that has the package but nothing DDC-capable falls through to the backlight.
Item {
    id: root

    readonly property bool available: root.bus >= 0
    property bool probed: false

    property int bus: -1
    // VCP 10's maximum is per-monitor and is frequently not 100.
    property int maxValue: 100
    property int rawValue: 0

    readonly property int percent: root.maxValue > 0 ? Math.round(root.rawValue / root.maxValue * 100) : 0

    function apply(value) {
        if (!root.available)
            return;
        var clamped = Math.max(0, Math.min(100, value));
        root.rawValue = Math.round(clamped / 100 * root.maxValue);
        writeDebounce.target = root.rawValue;
        writeDebounce.restart();
    }

    function refresh() {
        if (root.available && !reader.running)
            reader.running = true;
    }

    Process {
        // `command -v` first so a machine without ddcutil never tries to launch
        // it: Quickshell logs a warning for a binary it cannot find, and the old
        // implementation produced one on every start of this laptop.
        running: true
        command: ["bash", "-c", "command -v ddcutil >/dev/null 2>&1 && ddcutil detect --brief 2>/dev/null | grep -o '/dev/i2c-[0-9]*' | head -n1 || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.trim().match(/\/dev\/i2c-(\d+)/);
                if (match)
                    root.bus = parseInt(match[1], 10);
                root.probed = true;
                if (root.bus >= 0)
                    reader.running = true;
            }
        }
    }

    Process {
        id: reader

        command: ["ddcutil", "--bus", String(root.bus), "getvcp", "10", "--brief"]

        stdout: StdioCollector {
            onStreamFinished: {
                // "VCP 10 C <current> <max>"
                var parts = text.trim().split(/\s+/);
                if (parts.length >= 5) {
                    root.rawValue = parseInt(parts[3], 10) || 0;
                    root.maxValue = parseInt(parts[4], 10) || 100;
                }
            }
        }
    }

    Timer {
        id: writeDebounce

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

        command: ["ddcutil", "--bus", String(root.bus), "setvcp", "10", String(writeDebounce.target)]
    }
}
