pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    readonly property string application_name: {
        const levels = Hyprland.toplevels.values;
        for (let i = 0; i < levels.length; i++) {
            const level = levels[i].wayland;
            if (level.activated) {
                return String(level.appId);
            }
        }
        return "";
    }

    readonly property bool should_show: {
      return application_name != "";
    }
}
