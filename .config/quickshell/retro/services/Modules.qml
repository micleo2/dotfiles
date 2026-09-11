pragma Singleton

import QtQuick
import Quickshell
import ".."

// Which bar widgets run on this machine.
//
// Module choices are a fact about a machine, not about the config, so they
// live as a "modules" map in the machine-local settings.json under
// XDG_STATE_HOME (see Settings) rather than in the repo. Per module:
//
//   "auto"   show only on a laptop, and only if the hardware is present
//   true     show wherever the hardware is present
//   false    never show
//
// A module missing from the map is "auto". The hardware predicate applies even
// to an explicit `true`, so opting a module in on a machine that cannot
// support it is a no-op rather than a broken widget. A module that is not a
// laptop thing at all (the clock, a plugged-in gamepad) is marked
// `everywhere` in the table below, which makes "auto" mean every machine
// instead; `false` still hides it.
//
// `on` is the setting alone, resolved for this machine, and is what the bar
// gates on: a widget whose module is off is never built at all (BarSlot),
// and the singleton behind it reads the same answer to stay idle. `allow`
// adds the widget's own hardware test on top for its `available` flag.
Singleton {
    id: root

    // Every widget the bar can show, in bar order. The control center lists
    // these; it is not one of them, since it is the way back.
    readonly property var list: [
        { id: "workspaces", label: "Workspaces", everywhere: true },
        { id: "window", label: "Focused window", everywhere: true },
        { id: "clock", label: "Clock", everywhere: true },
        { id: "weather", label: "Weather", everywhere: true },
        { id: "tray", label: "Tray", everywhere: true },
        { id: "system", label: "System", everywhere: false },
        { id: "network", label: "Network", everywhere: false },
        { id: "bluetooth", label: "Bluetooth", everywhere: false },
        { id: "controller", label: "Controllers", everywhere: true },
        { id: "display", label: "Display", everywhere: false },
        { id: "keyboard", label: "Keyboard", everywhere: false },
        { id: "idle", label: "Stay awake", everywhere: false },
        { id: "battery", label: "Battery", everywhere: false },
        { id: "volume", label: "Volume", everywhere: true },
        { id: "notifications", label: "Notifications", everywhere: true }
    ]

    function entry(id) {
        for (var i = 0; i < root.list.length; i++) {
            if (root.list[i].id === id)
                return root.list[i];
        }
        return null;
    }

    function setting(id) {
        var value = Settings.modules[id];
        return value === undefined ? "auto" : value;
    }

    function on(id) {
        var value = root.setting(id);
        if (value === false)
            return false;
        if (value === true)
            return true;
        return root.byDefault(id);
    }

    function allow(id, hardware) {
        return !!hardware && root.on(id);
    }

    // What "auto" comes to on this machine.
    function byDefault(id) {
        var e = root.entry(id);
        return (e !== null && e.everywhere) || Host.isLaptop;
    }

    // Switch a module on or off. The file records only departures from the
    // default: a switch that lands where "auto" would have put it clears
    // the entry instead, so flipping a module off and on again leaves the
    // map as it was.
    function set(id, value) {
        root.write(id, value === root.byDefault(id) ? "auto" : value);
    }

    // JsonAdapter only notices whole-property assignment, so the map is
    // replaced rather than mutated in place or the write never lands.
    function write(id, value) {
        var next = {};
        for (var k in Settings.modules) {
            if (k !== id)
                next[k] = Settings.modules[k];
        }
        if (value !== "auto")
            next[id] = value;
        Settings.modules = next;
    }
}
