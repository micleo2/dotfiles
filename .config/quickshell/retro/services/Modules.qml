pragma Singleton

import QtQuick
import Quickshell
import ".."

// Which bar modules run on this machine.
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
// support it is a no-op rather than a broken widget.
Singleton {
    id: root

    function setting(id) {
        var value = Settings.modules[id];
        return value === undefined ? "auto" : value;
    }

    function allow(id, hardware) {
        if (!hardware)
            return false;
        var value = root.setting(id);
        if (value === false)
            return false;
        if (value === true)
            return true;
        return Host.isLaptop;
    }
}
