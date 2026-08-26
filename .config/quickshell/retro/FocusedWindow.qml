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

    readonly property string application_title: {
        const levels = Hyprland.toplevels.values;
        for (let i = 0; i < levels.length; i++) {
            const level = levels[i].wayland;
            if (level === null || level === undefined)
                continue;

            if (level.activated) {
                const title = level.title;
                return title === null || title === undefined ? "" : String(title);
            }
        }
        return "";
    }

    readonly property bool should_show: {
        return application_name != "";
    }

    // Chromium --app windows expose their app-id as chrome-<origin>__-<profile>,
    // which matches neither an icon nor a usable name.
    readonly property bool is_webapp: {
        return application_name.startsWith("chrome-");
    }

    // Fallback name/icon pairs for web-app windows, in priority order:
    // the window title (sanitized the way webapp-install names icons), then
    // the origin's first label.
    readonly property var webapp_candidates: {
        const candidates = [];
        if (!is_webapp)
            return candidates;

        if (application_title !== "") {
            const safe = application_title.toLocaleLowerCase()
                .replace(/[^a-z0-9]+/g, "-")
                .replace(/^-+|-+$/g, "");
            if (safe !== "")
                candidates.push({ name: application_title, icon: Quickshell.iconPath(safe, true) });
        }

        const origin = application_name.replace(/^chrome-/, "").replace(/__.*$/, "");
        const label = origin.replace(/^(www|web)\./, "").split('.')[0];
        if (label !== "")
            candidates.push({
                name: label[0].toLocaleUpperCase() + label.slice(1),
                icon: Quickshell.iconPath(label, true)
            });

        return candidates;
    }

    readonly property string application_icon_path: {
        if (!should_show)
            return "";

        const path = Quickshell.iconPath(application_name, true);
        if (path !== "")
            return path;

        // Reverse-DNS app-ids usually ship their icon under the last dot segment.
        const segments = application_name.split('.');
        const legacy = segments[segments.length - 1].toLocaleLowerCase();
        const legacyPath = Quickshell.iconPath(legacy, true);
        if (legacyPath !== "")
            return legacyPath;

        for (const c of webapp_candidates)
            if (c.icon !== "")
                return c.icon;

        return "";
    }

    readonly property string application_display_name: {
        if (!should_show)
            return "";

        const segments = application_name.split('.');
        const legacy = segments[segments.length - 1].toLocaleLowerCase();

        for (const c of webapp_candidates)
            if (c.icon !== "")
                return c.name;

        if (is_webapp && application_title !== "")
            return application_title;

        return legacy;
    }
}