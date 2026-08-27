import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
pragma Singleton

Singleton {
    id: root

    readonly property string application_name: {
        const levels = Hyprland.toplevels.values;
        for (let i = 0; i < levels.length; i++) {
            const level = levels[i].wayland;
            if (level === null || level === undefined)
                continue;

            if (level.activated)
                return String(level.appId);

        }
        return "";
    }

    // Desktop entry resolved from the window class: chromium --app windows
    // carry the forced chrome-<host>__<path>-<profile> class, and webapp
    // launchers record it as StartupWMClass, so heuristicLookup() (exact id,
    // then StartupWMClass) maps the window back to its entry's name + icon.
    readonly property var application_entry: {
        if (!should_show)
            return null;
        return DesktopEntries.heuristicLookup(application_name);
    }

    readonly property bool should_show: {
        return application_name != "";
    }

    readonly property string application_icon_path: {
        if (!should_show)
            return "";

        const entry = application_entry;
        if (entry !== null && entry !== undefined && entry.icon !== "") {
            const icon = String(entry.icon);
            if (icon.startsWith("/"))
                return icon;
            const entryPath = Quickshell.iconPath(icon, true);
            if (entryPath !== "")
                return entryPath;
        }

        const path = Quickshell.iconPath(application_name, true);
        if (path !== "")
            return path;

        // Reverse-DNS app-ids usually ship their icon under the last dot segment.
        const segments = application_name.split('.');
        const legacy = segments[segments.length - 1].toLocaleLowerCase();
        const legacyPath = Quickshell.iconPath(legacy, true);
        if (legacyPath !== "")
            return legacyPath;

        return "";
    }

    readonly property string application_display_name: {
        if (!should_show)
            return "";

        const entry = application_entry;
        if (entry !== null && entry !== undefined && entry.name !== "")
            return String(entry.name);

        const segments = application_name.split('.');
        return segments[segments.length - 1].toLocaleLowerCase();
    }
}