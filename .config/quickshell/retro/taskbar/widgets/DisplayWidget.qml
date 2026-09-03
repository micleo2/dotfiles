pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "../../ui" as Ui
import "../.."
import "../../services"

// Display scale, per monitor, plus the one global text-size knob.
//
// This is the module most likely to be switched on for the desktop too, so
// nothing in it assumes a laptop: the scale ladder is derived from whatever
// monitors Hyprland reports.
Item {
    id: root

    required property var barScreen
    required property bool primary

    readonly property bool available: Modules.allow("display", true)

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.available

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true
        onClicked: popup.toggle()

        Ui.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: "display_settings"
        }
    }

    Ui.Popup {
        id: popup

        anchorItem: chip
        barScreen: root.barScreen
        cardWidth: 380

        Ui.SectionLabel {
            text: "Scale"
        }

        Repeater {
            model: Hyprland.monitors

            Column {
                id: monitorEntry

                required property var modelData

                readonly property var stops: DisplayScale.validScales(monitorEntry.modelData)

                width: parent.width
                spacing: 4

                Ui.Label {
                    text: monitorEntry.modelData.name + "  " + monitorEntry.modelData.width + "x" + monitorEntry.modelData.height
                    size: Math.round(Config.settings.bar.fontSize * 0.8)
                    opacity: 0.75
                }

                Ui.PopupSlider {
                    rowKey: "scale:" + monitorEntry.modelData.name
                    cursorKey: popup.cursorKey
                    onCursorEntered: popup.cursorKey = "scale:" + monitorEntry.modelData.name

                    stops: monitorEntry.stops
                    index: {
                        var best = 0;
                        for (var i = 0; i < monitorEntry.stops.length; i++) {
                            if (Math.abs(monitorEntry.stops[i] - monitorEntry.modelData.scale) < Math.abs(monitorEntry.stops[best] - monitorEntry.modelData.scale))
                                best = i;
                        }
                        return best;
                    }
                    onMoved: (index) => DisplayScale.applyScale(monitorEntry.modelData, monitorEntry.stops[index])
                }

                Ui.Label {
                    text: "×" + DisplayScale.formatScale(monitorEntry.modelData.scale) + "  →  " + Math.round(monitorEntry.modelData.width / monitorEntry.modelData.scale) + "x" + Math.round(monitorEntry.modelData.height / monitorEntry.modelData.scale)
                    size: Math.round(Config.settings.bar.fontSize * 0.8)
                    opacity: 0.6
                }
            }
        }

        Ui.SectionLabel {
            text: "Text size"
        }

        Ui.PopupSlider {
            id: textSlider

            readonly property var sizes: {
                var out = [];
                for (var px = DisplayScale.minSize; px <= DisplayScale.maxSize; px++)
                    out.push(px);
                return out;
            }

            rowKey: "text"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "text"

            stops: textSlider.sizes
            index: DisplayScale.textSizePx - DisplayScale.minSize
            onMoved: (index) => DisplayScale.setTextSize(textSlider.sizes[index])
        }

        Ui.Label {
            text: DisplayScale.textSizePx + "px   gtk ×" + DisplayScale.gtkFactor.toFixed(2) + "   term " + DisplayScale.terminalPt + "pt"
            size: Math.round(Config.settings.bar.fontSize * 0.8)
            opacity: 0.6
        }

        Ui.SectionLabel {
            text: "Theme"
        }

        // One row per palette in Config.themes; the marker is the one in use.
        Repeater {
            model: Config.themeNames

            Ui.PopupRow {
                required property var modelData

                rowKey: "theme:" + modelData
                cursorKey: popup.cursorKey
                onCursorEntered: popup.cursorKey = "theme:" + modelData

                glyph: "palette"
                text: modelData
                selected: Settings.theme === modelData
                onClicked: Settings.theme = modelData
            }
        }
    }

    IpcHandler {
        // Bars are instantiated per screen; only the primary one
        // claims the target, or a second monitor collides with it.
        target: "display"
        enabled: root.primary

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by
        // the `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function toggle(): void {
            popup.toggle();
        }

        function open(): void {
            popup.open();
        }

        function close(): void {
            popup.close();
        }

        // Open with the keyboard cursor placed, for the SUPER+T submap
        // (hypr/submap-topbar.lua).
        function focus(): void {
            if (root.available)
                popup.openWithCursor();
        }

        // Natural keybind targets, and the only way to drive the text size
        // without the popup open.
        function textUp(): void {
            DisplayScale.setTextSize(DisplayScale.textSizePx + 1);
        }

        function textDown(): void {
            DisplayScale.setTextSize(DisplayScale.textSizePx - 1);
        }

        // Switch palette by name, or cycle with "next"; returns the result.
        function theme(name: string): string {
            var names = Config.themeNames;
            var want = String(name || "");
            if (want === "next" || want === "") {
                var at = names.indexOf(Settings.theme);
                want = names[(at + 1) % names.length];
            }
            if (names.indexOf(want) === -1)
                return "unknown theme " + want + " (have " + names.join(" ") + ")";
            Settings.theme = want;
            return want;
        }

        function textReset(): void {
            DisplayScale.setTextSize(DisplayScale.defaultSize);
        }

        // Set the focused monitor's scale, snapped to the nearest value that
        // monitor actually accepts. Takes a string because IPC arguments are
        // always strings.
        function scale(value: string): string {
            var monitor = Hyprland.focusedMonitor;
            if (!monitor)
                return "no focused monitor";
            var wanted = parseFloat(value);
            if (!isFinite(wanted))
                return "not a number: " + value;
            var snapped = DisplayScale.snap(monitor, wanted);
            if (snapped === null)
                return monitor.name + " cannot be scaled near " + wanted;
            DisplayScale.applyScale(monitor, snapped);
            return monitor.name + " -> " + DisplayScale.formatScale(snapped);
        }
    }
}
