pragma Singleton

import Quickshell
import Quickshell.Hyprland

// Which screen a module opened from a keybind appears on: the one with
// focus, or the first when Hyprland reports none. Read when the module
// opens, not bound, so it stays where it was opened.
Singleton {
    readonly property string focusedName: {
        var monitor = Hyprland.focusedMonitor;
        if (monitor && monitor.name)
            return monitor.name;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
}
