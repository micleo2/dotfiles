pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../ui" as Ui
import "../.."
import "../../services"

// System overview. The chip is just VRAM used ("2.4G") — the one number worth
// a permanent glance; CPU and GPU utilization live in the popup. It all rides
// on SystemStats.gpuAvailable, so a machine with no GPU (the laptop) shows no
// chip at all. The readout goes urgent when VRAM is 90% full.
Item {
    id: root

    required property var barScreen
    required property bool primary

    readonly property bool available: Modules.allow("system", true)

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.available && SystemStats.gpuAvailable

    function loadColor(percent) {
        return percent >= 90 ? Config.colors.urgent : Config.colors.text;
    }

    function gib(mib) {
        return (mib / 1024).toFixed(1);
    }

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true
        onClicked: popup.toggle()

        Ui.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: "memory_alt"
        }

        Ui.Label {
            anchors.verticalCenter: parent.verticalCenter
            color: root.loadColor(SystemStats.vramPercent)
            text: root.gib(SystemStats.vramUsedMib) + "G"
        }
    }

    Ui.Popup {
        id: popup

        anchorItem: chip
        barScreen: root.barScreen
        cardWidth: 300

        Ui.SectionLabel {
            text: "CPU"
        }

        Ui.PopupRow {
            interactive: false
            glyph: "memory"
            text: "Utilization"
            detail: SystemStats.cpuPercent + "%"
        }

        Ui.SectionLabel {
            visible: SystemStats.gpuAvailable
            text: "GPU"
        }

        Ui.PopupRow {
            interactive: false
            visible: SystemStats.gpuAvailable
            glyph: "developer_board"
            text: "Utilization"
            detail: SystemStats.gpuPercent + "%"
        }

        Ui.PopupRow {
            interactive: false
            visible: SystemStats.gpuAvailable
            glyph: "memory_alt"
            text: "VRAM"
            detail: root.gib(SystemStats.vramUsedMib) + " / " + root.gib(SystemStats.vramTotalMib) + " GiB"
        }
    }

    IpcHandler {
        // Bars are instantiated per screen; only the primary one
        // claims the target, or a second monitor collides with it.
        target: "system"
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
        // (hypr/submap-topbar.lua). Gated on the same predicate as the
        // chip: no GPU, no panel.
        function focus(): void {
            if (root.visible)
                popup.openWithCursor();
        }
    }
}
