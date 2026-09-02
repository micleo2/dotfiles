import QtQuick
import Quickshell
import Quickshell.Io

// Internal panel backlight, via /sys/class/backlight.
//
// Reads come straight from sysfs rather than from brightnessctl: the file is
// world-readable, so a FileView is both faster than spawning a process and — with
// watchChanges — picks up changes made by anything else on the system for free.
// Writes still go through brightnessctl, because the sysfs node is root-owned and
// brightnessctl is what carries the privileges to set it.
//
// The backlight only ever drives the internal panel, so it is available only
// while that panel is the focused output (or no output is known at all). With
// an external monitor focused it stays out of the way rather than dimming the
// laptop screen in response to a key meant for the monitor in front of you.
Item {
    id: root

    // Connector name of the focused monitor, e.g. "eDP-1"; "" when unknown.
    property string output: ""

    readonly property bool internalFocused: root.output === "" || /^(eDP|LVDS|DSI)/i.test(root.output)
    readonly property bool available: root.device !== "" && root.maxValue > 0 && root.internalFocused
    property bool probed: false

    property string device: ""
    property int maxValue: 0
    property int rawValue: 0

    readonly property int percent: root.maxValue > 0 ? Math.round(root.rawValue / root.maxValue * 100) : 0

    function apply(value) {
        if (!root.available)
            return;
        // Set optimistically so the reading is correct the instant it is asked
        // for; the file watch confirms it a moment later with the real value.
        root.rawValue = Math.round(Math.max(0, Math.min(100, value)) / 100 * root.maxValue);
        Quickshell.execDetached(["brightnessctl", "-q", "-d", root.device, "set", Math.round(value) + "%"]);
    }

    function refresh() {
        reader.reload();
    }

    Process {
        // Run through bash so a missing brightnessctl cannot produce a
        // "process failed to start" warning, and so the device heuristic stays
        // in one place. The ordering mirrors omarchy-hw-display: apple-gmux
        // first where it exists, then the GPU's own PWM, and never the T2 Mac
        // Touch Bar backlight, which does not drive the panel.
        running: true
        command: ["bash", "-c", 'd=""; for c in /sys/class/backlight/gmux_backlight /sys/class/backlight/amdgpu_bl* /sys/class/backlight/intel_backlight /sys/class/backlight/acpi_video*; do [ -e "$c" ] && { d="$c"; break; }; done; [ -n "$d" ] || d="$(ls -d /sys/class/backlight/* 2>/dev/null | grep -v appletb_backlight | head -n1)"; [ -n "$d" ] && printf "%s\\n%s\\n" "${d##*/}" "$(cat "$d/max_brightness" 2>/dev/null)"; exit 0']

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                if (lines.length >= 2 && lines[0] !== "") {
                    root.device = lines[0].trim();
                    root.maxValue = parseInt(lines[1].trim(), 10) || 0;
                }
                root.probed = true;
            }
        }
    }

    FileView {
        id: reader

        path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        watchChanges: true
        printErrors: false

        onFileChanged: reader.reload()
        onLoaded: {
            var value = parseInt(reader.text().trim(), 10);
            if (!isNaN(value))
                root.rawValue = value;
        }
    }
}
