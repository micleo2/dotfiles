pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../ui" as Ui
import "../.."
import "../../services"
import "../../keymap" as Keymap_

// The QMK boards: which layer the one you are typing on is on, and its
// backlight.
//
// The chip shows the active board's layer name from its exported keymap
// (keymap/<board>.json) and scrolls the backlight. The popup has the backlight slider and
// toggle, one row per layer to toggle it from the mouse, and a row that
// opens the layout viewer.
//
// Shown wherever the board is plugged in, subject to the modules map like
// every other chip (Modules.allow).
Item {
    id: root

    required property var barScreen
    required property bool primary

    readonly property bool available: Modules.allow("keyboard", Qmk.anyPresent)

    readonly property int stepPercent: Qmk.step
    readonly property var steps: {
        var out = [];
        for (var v = root.stepPercent; v <= 100; v += root.stepPercent)
            out.push(v);
        return out;
    }

    readonly property var boardData: Keymap_.Keymap.cache[Qmk.active] || null
    readonly property var layers: root.boardData ? root.boardData.layers : []
    readonly property var layerEntry: Keymap_.Keymap.layerFor(Qmk.active, Qmk.layer)
    readonly property string layerName: root.layerEntry ? String(root.layerEntry.name) : "L" + Qmk.layer

    property real wheelAccumulator: 0

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.available

    function handleWheel(event) {
        var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
        root.wheelAccumulator += Math.max(-120, Math.min(120, delta));
        while (Math.abs(root.wheelAccumulator) >= 120) {
            var direction = root.wheelAccumulator > 0 ? 1 : -1;
            root.wheelAccumulator -= direction * 120;
            Qmk.adjust(direction * root.stepPercent);
        }
    }

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                Keymap_.Keymap.toggle();
            else
                popup.toggle();
        }
        onScrolled: (event) => root.handleWheel(event)

        Ui.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: Qmk.capsWord ? "keyboard_capslock" : "keyboard"
        }

        Ui.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.layerName
        }
    }

    Ui.Popup {
        id: popup

        anchorItem: chip
        barScreen: root.barScreen
        cardWidth: 320

        // Which board the popup is about; click to switch when two are in.
        Ui.PopupRow {
            rowKey: "board"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "board"

            glyph: "keyboard"
            text: root.boardData ? String(root.boardData.title) : Qmk.active
            detail: Qmk.present.length > 1 ? "click: " + Qmk.present.filter(b => b !== Qmk.active).join(", ") : ""
            onClicked: {
                var others = Qmk.present.filter(b => b !== Qmk.active);
                if (others.length > 0)
                    Qmk.activate(others[0]);
            }
        }

        Ui.SectionLabel {
            text: "Backlight"
        }

        Ui.PopupSlider {
            rowKey: "level"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "level"

            stops: root.steps
            index: Math.round(Qmk.percent / root.stepPercent) - 1
            onMoved: (index) => Qmk.set(root.steps[index])
        }

        Ui.PopupToggle {
            rowKey: "rgb"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "rgb"

            text: Qmk.rgbOn ? "RGB  " + Qmk.percent + "%" : "RGB  off"
            checked: Qmk.rgbOn
            onToggled: (value) => Qmk.setEnabled(value)
        }

        Ui.SectionLabel {
            text: "Layers"
        }

        // The marker is every layer the board has active, not only the
        // highest, so a toggled-on Graphite shows under a held NAV. Rows
        // carry the board's own layer number, which the export keeps.
        Repeater {
            model: root.layers

            Ui.PopupRow {
                id: layerRow

                required property var modelData
                required property int index

                readonly property int boardLayer: Number(modelData.index)

                rowKey: "layer:" + index
                cursorKey: popup.cursorKey
                onCursorEntered: popup.cursorKey = "layer:" + layerRow.index

                glyph: layerRow.boardLayer === Qmk.layer ? "layers" : "layers_clear"
                text: String(modelData.name) + "  " + String(modelData.title)
                selected: Qmk.layerActive(layerRow.boardLayer)
                // The base layer cannot be toggled off; clicking it clears
                // every other layer instead.
                onClicked: layerRow.boardLayer === 0 ? Qmk.clearLayers() : Qmk.toggleLayer(layerRow.boardLayer)
            }
        }

        Ui.SectionLabel {
            text: "Keymap"
        }

        Ui.PopupRow {
            rowKey: "keymap"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "keymap"

            glyph: "grid_on"
            text: "Show layout"
            detail: "SUPER+U k"
            onClicked: {
                popup.close();
                Keymap_.Keymap.open();
            }
        }
    }

    IpcHandler {
        // Bars are instantiated per screen; only the primary one claims the
        // target, or a second monitor collides with it.
        target: "keyboard"
        enabled: root.primary

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
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
    }
}
