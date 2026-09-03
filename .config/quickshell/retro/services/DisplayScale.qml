pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

// Monitor scale and the one global text-size knob.
Singleton {
    id: root

    // ---------------------------------------------------------------- scale --

    // Hyprland only accepts a scale that snaps to a multiple of 1/120 *and*
    // still divides the monitor into an integral logical size; anything else is
    // refused and the monitor silently keeps its old scale. So the ladder is
    // computed from each monitor's real resolution rather than hardcoded.
    readonly property var preferredStops: [1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 3]

    function divides(px, scale) {
        var logical = px / scale;
        return Math.abs(logical - Math.round(logical)) < 0.001;
    }

    // Nudge a desired scale onto the nearest 1/120 step the monitor accepts,
    // searching outward a little before giving up on that stop entirely.
    function snap(monitor, desired) {
        var base = Math.round(desired * 120);
        for (var d = 0; d <= 12; d++) {
            for (var sign = 0; sign < 2; sign++) {
                var n = sign === 0 ? base + d : base - d;
                if (n < 120)
                    continue;
                var s = n / 120;
                // Returned unrounded on purpose. Rounding to a few decimals
                // silently breaks the very property just checked: 200/120
                // divides 2880x1920 exactly, but 1.667 does not.
                if (root.divides(monitor.width, s) && root.divides(monitor.height, s))
                    return s;
            }
        }
        return null;
    }

    // Short form for display; never used to talk to Hyprland.
    function formatScale(scale) {
        return (Math.round(scale * 1000) / 1000).toString();
    }

    function validScales(monitor) {
        var out = [];
        if (!monitor)
            return out;
        for (var i = 0; i < root.preferredStops.length; i++) {
            var s = root.snap(monitor, root.preferredStops[i]);
            if (s !== null && out.indexOf(s) === -1)
                out.push(s);
        }
        return out;
    }

    // Descriptions survive a replug where connector names do not.
    function keyFor(monitor) {
        return monitor.description && monitor.description !== "" ? monitor.description : monitor.name;
    }

    function applyScale(monitor, scale) {
        var mode = monitor.width + "x" + monitor.height;
        var rate = monitor.lastIpcObject && monitor.lastIpcObject.refreshRate;
        if (rate)
            mode += "@" + rate;
        // Enough digits that Hyprland rounds back to the same 1/120 step.
        // Position stays `auto`: changing scale changes the logical size, and
        // pinning the old coordinates can overlap the neighbouring output.
        var value = scale.toFixed(6);

        if (Hyprland.usingLua) {
            // This config drives Hyprland through the Lua plugin, which
            // replaces the legacy parser — `hyprctl keyword` refuses outright
            // ("keyword can't work with non-legacy parsers. Use eval.").
            Quickshell.execDetached(["hyprctl", "eval", 'hl.monitor({ output = "' + monitor.name + '", mode = "' + mode + '", position = "auto", scale = "' + value + '" })']);
        } else {
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", monitor.name + "," + mode + ",auto," + value]);
        }
        Settings.setMonitorScale(root.keyFor(monitor), scale);
        monitorRefresh.kick();
    }

    Timer {
        id: monitorRefresh

        // Hyprland fires no event when a monitor's scale changes, so Quickshell
        // keeps serving the old value and the UI reads as if nothing happened.
        // The change also lands asynchronously, so one refresh can still be too
        // early — poll briefly instead of guessing a single delay.
        property int ticks: 0

        interval: 150
        repeat: true
        onTriggered: {
            Hyprland.refreshMonitors();
            if (++monitorRefresh.ticks >= 6)
                monitorRefresh.stop();
        }

        function kick() {
            monitorRefresh.ticks = 0;
            monitorRefresh.restart();
        }
    }


    // `hyprctl keyword` is runtime-only, so a config reload drops it and a
    // freshly plugged monitor never had it. Re-assert what was chosen.
    function reapply() {
        var saved = Settings.monitorScales;
        for (var i = 0; i < Hyprland.monitors.values.length; i++) {
            var m = Hyprland.monitors.values[i];
            var want = saved[root.keyFor(m)];
            if (want !== undefined && Math.abs(m.scale - want) > 0.001)
                root.applyScale(m, want);
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "monitoradded" || event.name === "configreloaded")
                reapplyTimer.restart();
        }
    }

    Timer {
        id: reapplyTimer

        // Let Hyprland finish settling the new layout before overriding it.
        interval: 600
        onTriggered: root.reapply()
    }

    Component.onCompleted: reapplyTimer.restart()

    // ------------------------------------------------------------ text size --

    // One knob, three consumers, mirroring omarchy's omarchy-display-text-size:
    // the shell's own font, GTK's text-scaling-factor, and the terminal's point
    // size — all anchored so 12px is "default".
    readonly property int minSize: 9
    readonly property int maxSize: 20
    readonly property int defaultSize: 12
    readonly property int textSizePx: Settings.textSizePx

    // Point size of the GTK interface font, used to quantise the scaling factor
    // so the font lands on a whole point size. Unquantised ratios clip GTK4
    // menu ascenders on scale-1 monitors.
    property real gtkFontPt: 11

    readonly property real gtkFactor: Math.round(root.gtkFontPt * root.textSizePx / root.defaultSize) / root.gtkFontPt

    // Omarchy anchors the terminal at 9pt because that is its own default. Every
    // leg here is instead anchored to what this machine already had, so leaving
    // the slider at 12 reproduces the current setup exactly and changes nothing.
    readonly property int terminalBasePt: 12
    readonly property int terminalPt: Math.round(root.textSizePx * root.terminalBasePt / root.defaultSize)

    function setTextSize(px) {
        var clamped = Math.max(root.minSize, Math.min(root.maxSize, px));
        Settings.textSizePx = clamped;
        root.applyTextSize();
    }

    function applyTextSize() {
        var factor = Math.round(root.gtkFontPt * root.textSizePx / root.defaultSize) / root.gtkFontPt;
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "text-scaling-factor", factor.toFixed(4)]);
        // Written to an overlay file that kitty.conf `include`s, rather than
        // patched into kitty.conf itself the way omarchy does: that file is a
        // symlink into the dotfiles repo shared with the desktop, and a slider
        // has no business dirtying it.
        kittyOverlay.setText("# Written by the retro shell's text-size control.\nfont_size " + root.terminalPt + "\n");
        Quickshell.execDetached(["pkill", "-USR1", "kitty"]);
    }

    FileView {
        id: kittyOverlay

        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/kitty/text-size.conf"
        printErrors: false
    }

    Process {
        // Read the GTK interface font once so the factor can be quantised.
        running: true
        command: ["gsettings", "get", "org.gnome.desktop.interface", "font-name"]

        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/([0-9]+(?:\.[0-9]+)?)'?\s*$/);
                if (match)
                    root.gtkFontPt = parseFloat(match[1]);
            }
        }
    }
}
