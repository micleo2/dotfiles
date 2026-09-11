pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// The gamepads plugged in or paired right now, for the controller chip.
//
// Presence comes from a scan script beside this file, which asks udev which
// input devices are joysticks: the kernel gives a js node to anything with
// absolute axes (a virtual mouse, the DualSense's motion sensors), and
// udev's ID_INPUT_JOYSTICK is what separates the real pads, as it does for
// SDL and Steam. The scan runs when udev reports a joystick node coming or
// going, through a long-lived `udevadm monitor` (Quickshell has no libudev
// binding, and inotify on /dev/input fires before udev has finished setting
// the node up), debounced because one pad arrives as a burst of nodes, and
// once whenever the monitor (re)starts, which covers a pad already present
// at launch. Only if the monitor cannot run at all does a slow poll stand
// in for it.
//
// Battery is UPower's job: upowerd already tracks each pad's power_supply as
// a GamingInput device and pushes changes over D-Bus, so the shell gets live
// numbers without polling anything. The pad's power_supply name is upowerd's
// native-path for it, which is the join. The scan's own capacity is the
// fallback for the moment before upowerd has picked the pad up.
//
// Nothing runs unless the controller module is on (Modules): a switched-off
// chip must cost nothing, and this singleton is shared by every bar anyway,
// so a second monitor never spawns a second monitor process.
Singleton {
    id: root

    readonly property bool enabled: Modules.on("controller")

    readonly property string scanPath: Quickshell.shellDir + "/services/controllers/scan.py"

    // One entry per pad, as the scan printed it: { key, name, kernelName,
    // transport, vid, pid, uniq, powerSupply, capacity, status }.
    property var devices: []
    readonly property int count: root.devices.length

    function upowerDevice(pad) {
        if (!pad.powerSupply)
            return null;
        return Host.findDevice(UPowerDeviceType.GamingInput, function (d) {
            return d.nativePath === pad.powerSupply;
        });
    }

    // { percent: 0-100, charging: bool, full: bool } or null when nothing
    // reports one.
    function battery(pad) {
        var d = root.upowerDevice(pad);
        if (d && d.ready && d.isPresent)
            return {
                percent: Host.percent(d),
                charging: Host.charging(d),
                full: Host.full(d)
            };
        if (pad.capacity !== null && pad.capacity !== undefined)
            return {
                percent: pad.capacity,
                charging: pad.status === "Charging",
                full: pad.status === "Full"
            };
        return null;
    }

    function batteryText(pad) {
        var b = root.battery(pad);
        if (!b)
            return "";
        if (b.full)
            return b.percent + "% full";
        return b.percent + "%" + (b.charging ? " charging" : "");
    }

    function parse(text) {
        var list;
        try {
            list = JSON.parse(text);
        } catch (e) {
            list = null;
        }
        if (!Array.isArray(list)) {
            console.warn("controllers: unreadable scan output, listing nothing");
            root.devices = [];
            return;
        }
        root.devices = list;
    }

    Command {
        id: scan

        command: ["python3", root.scanPath]
        // Only the fallback for a session where udev cannot be watched.
        polling: root.enabled && monitor.failed
        interval: 30000
        onCollected: (text) => root.parse(text)
    }

    Daemon {
        id: monitor

        command: ["udevadm", "monitor", "--udev", "--subsystem-match=input"]
        wanted: root.enabled

        onStarted: scan.run()

        stdout: SplitParser {
            // Only joystick nodes: a keyboard replug is a burst of input
            // events too, and joydev announces its js node on its own line
            // both coming and going.
            onRead: (line) => {
                if (/ (add|remove) +\/.*\/js[0-9]+ /.test(line))
                    debounce.restart();
            }
        }
    }

    // A pad shows up as several input nodes in quick succession; one scan
    // after the burst is enough.
    Timer {
        id: debounce

        interval: 300
        onTriggered: scan.run()
    }
}
