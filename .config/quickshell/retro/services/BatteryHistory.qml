pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery level over the last few hours, for the battery popup's plot.
//
// Nothing is logged here. upowerd already records the charge every time it
// changes (it polls the battery every 30 s and keeps the file under
// /var/lib/upower across reboots), and serves it back over D-Bus as
// GetHistory. That file is root-only, the call is not, so it goes through
// busctl. The aggregate DisplayDevice refuses the call; the real battery
// device answers it.
//
// The daemon writes a point per ~1% step, so a flat stretch (sat at 100% on
// the charger) has no points at all and the last value is carried forward.
// A value of 0 in state 0 is the daemon's own marker for stopping and
// starting again (suspend, reboot): a gap in the record, not an empty
// battery, and the series shows it as one.
Singleton {
    id: root

    // Seconds of history shown, one of `spans`; the plot cycles it.
    readonly property var spans: [21600, 86400, 604800]
    property int span: 86400
    // One bucket per pixel column the chart draws. The chart sets it from its
    // own width so the columns tile it exactly.
    property int buckets: 140

    // Oldest first, `buckets` long: { pct: 0-100 or null for a gap, charging: bool }.
    property var series: []
    property bool loading: false
    property string error: ""

    readonly property var device: Host.findDevice(UPowerDeviceType.Battery, function (d) {
        return d.isLaptopBattery;
    })

    // upowerd names the object after the sysfs path, with characters outside
    // [A-Za-z0-9] escaped. "BAT1" needs none; a stranger name would.
    readonly property string objectPath: root.device ? "/org/freedesktop/UPower/devices/battery_" + root.device.nativePath : ""

    function cycle(direction) {
        var i = root.spans.indexOf(root.span);
        var n = root.spans.length;
        root.span = root.spans[((i < 0 ? 0 : i) + direction + n) % n];
    }

    function refresh() {
        if (root.objectPath === "") {
            root.error = "No battery";
            root.series = [];
            return;
        }
        // A little past the window so the value at its left edge is known,
        // and several raw points per bucket so upowerd's own re-binning never
        // lands coarser than the columns.
        var extra = Math.round(root.span * 0.1);
        cmd.command = ["busctl", "--system", "--json=short", "call", "org.freedesktop.UPower", root.objectPath, "org.freedesktop.UPower.Device", "GetHistory", "suu", "charge", String(root.span + extra), String(root.buckets * 4)];
        root.loading = true;
        cmd.run();
    }

    function isGap(p) {
        return p.state === 0 && p.pct === 0;
    }

    function parse(text) {
        root.loading = false;
        var raw;
        try {
            raw = JSON.parse(text).data[0];
        } catch (e) {
            root.error = text.trim() === "" ? "No history" : "Bad history";
            root.series = [];
            return;
        }
        // busctl hands the list newest first.
        var pts = raw.map(function (p) {
            return { t: p[0], pct: p[1], state: p[2] };
        }).reverse();

        var now = Math.floor(Date.now() / 1000);
        var start = now - root.span;
        var width = root.span / root.buckets;
        var out = [];
        var i = 0;
        var last = null;
        var charging = false;

        // Where the level stood at the window's left edge, unless the daemon
        // was down between the last known point and it.
        for (; i < pts.length && pts[i].t < start; i++) {
            if (root.isGap(pts[i])) {
                last = null;
            } else {
                last = pts[i].pct;
                charging = pts[i].state === 1;
            }
        }
        for (var b = 0; b < root.buckets; b++) {
            var end = start + (b + 1) * width;
            var sum = 0;
            var n = 0;
            for (; i < pts.length && pts[i].t < end; i++) {
                if (root.isGap(pts[i])) {
                    last = null;
                    continue;
                }
                last = pts[i].pct;
                charging = pts[i].state === 1;
                sum += pts[i].pct;
                n++;
            }
            if (n > 0)
                out.push({ pct: sum / n, charging: charging });
            else
                out.push({ pct: last, charging: last === null ? false : charging });
        }
        // The live reading is newer than anything the daemon has written.
        if (root.device && out.length > 0) {
            out[out.length - 1] = {
                pct: root.device.percentage * 100,
                charging: root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.PendingCharge
            };
        }
        root.series = out;
        root.error = "";
    }

    Command {
        id: cmd

        onCollected: (text) => root.parse(text)
    }

    onSpanChanged: root.refresh()
}
