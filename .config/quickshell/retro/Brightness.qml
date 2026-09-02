pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "brightness" as Backends

// Display brightness, over whichever backend this machine actually has.
//
// The backend is chosen, not configured: ddcutil drives external monitors over
// DDC/CI and wins when it is installed *and* detects a display; otherwise the
// internal panel backlight is driven through brightnessctl. That covers the
// desktop (external monitor) and the laptop (eDP panel) from one checkout with
// nothing host-specific to set.
//
// Each backend exposes the same four members — `available`, `percent`,
// `apply(percent)` and `refresh()` — so adding a third is one file plus one line
// in `backends` below.
Singleton {
    id: root

    readonly property var backends: [ddc, backlight]

    readonly property var backend: {
        for (var i = 0; i < root.backends.length; i++) {
            if (root.backends[i].available)
                return root.backends[i];
        }
        return null;
    }

    readonly property bool available: root.backend !== null
    // True once every backend has finished probing, so "no backend" can be told
    // apart from "still looking".
    readonly property bool probed: ddc.probed && backlight.probed
    readonly property int percent: root.backend ? root.backend.percent : 0
    readonly property string backendName: {
        if (root.backend === ddc)
            return "ddcutil";
        if (root.backend === backlight)
            return "brightnessctl";
        return "none";
    }

    property int step: 10

    // The OSD draws one segment per step, so a keypress always moves the bucket
    // by exactly one block. Deriving it here rather than hardcoding ten keeps
    // the two from drifting apart if the step ever changes.
    readonly property int segments: Math.max(1, Math.round(100 / root.step))

    // The OSD listens for this. It fires on a deliberate change only — an
    // external one moves `percent` without putting the OSD on screen.
    signal brightnessChanged

    function set(value) {
        if (!root.available)
            return;
        root.backend.apply(Math.max(0, Math.min(100, value)));
        root.brightnessChanged();
    }

    function adjust(delta) {
        root.set(root.percent + delta);
    }

    Backends.DdcBackend {
        id: ddc
    }

    Backends.BacklightBackend {
        id: backlight
    }

    IpcHandler {
        target: "brightness"

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function up(): string {
            root.adjust(root.step);
            return root.percent + "%";
        }

        function down(): string {
            root.adjust(-root.step);
            return root.percent + "%";
        }

        function set(value: string): string {
            var parsed = parseInt(value, 10);
            if (isNaN(parsed))
                return "not a number: " + value;
            root.set(parsed);
            return root.percent + "%";
        }

        function status(): string {
            return root.available ? root.percent + "% via " + root.backendName : "no brightness backend";
        }
    }
}
