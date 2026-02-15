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
            if (level === null || level === undefined)
                continue;
            if (level.activated) {
                return String(level.appId);
            }
        }
        return "";
    }

    readonly property string application_display_name: {
        if (!should_show)
            return "";
        const segments = application_name.split('.');
        return segments[segments.length - 1].toLocaleLowerCase();
    }

    readonly property bool should_show: {
        return application_name != "";
    }

    readonly property string application_icon_path: {
        if (!should_show)
            return "";
        return Quickshell.iconPath(application_name, true);
    }
}
