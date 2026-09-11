pragma ComponentBehavior: Bound

import QtQuick
import "../.."
import "../../ui" as Ui
import "../../services"

// System overview. The chip is just VRAM used ("2.4G") — the one number worth
// a permanent glance; CPU and GPU utilization live in the popup. It all rides
// on SystemStats.gpuAvailable, so a machine with no GPU (the laptop) shows no
// chip at all.
Ui.Chip {
    id: root

    required property var barScreen
    required property bool primary

    readonly property bool available: Modules.allow("system", SystemStats.gpuAvailable)

    visible: root.available

    function gib(mib) {
        return (mib / 1024).toFixed(1);
    }

    interactive: true
    onClicked: popup.toggle()

    Ui.Glyph {
        anchors.verticalCenter: parent.verticalCenter
        slot: Config.settings.bar.iconSlot
        text: "memory_alt"
    }

    Ui.Label {
        anchors.verticalCenter: parent.verticalCenter
        text: root.gib(SystemStats.vramUsedMib) + "G"
    }

    Ui.Popup {
        id: popup

        anchorItem: root
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

    Ui.PopupIpc {
        target: "system"
        enabled: root.primary
    }
}
