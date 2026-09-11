pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../ui" as Ui
import "../.."
import "../../services"

// Connected gamepads. The chip is a pad glyph, with a count once there is
// more than one, and shows only while something is connected; the popup
// lists each pad with its link and battery. Pure readout: there is nothing
// to do to a pad from the bar.
Ui.Chip {
    id: root

    required property var barScreen
    required property bool primary

    // A pad being plugged in is the hardware test. The scanning that finds
    // one runs on the module setting alone (Controllers), since it cannot
    // wait for its own result.
    readonly property bool available: Modules.allow("controller", Controllers.count > 0)

    visible: root.available

    // The chip leaves the layout with the last pad, and the popup resolves
    // its anchor only on open, so an open card would be left hanging over
    // whatever slid into the gap.
    onAvailableChanged: {
        if (!root.available)
            popup.close();
    }

    interactive: true
    onClicked: popup.toggle()

    Ui.Glyph {
        anchors.verticalCenter: parent.verticalCenter
        slot: Config.settings.bar.iconSlot
        text: "stadia_controller"
    }

    Ui.Label {
        anchors.verticalCenter: parent.verticalCenter
        visible: Controllers.count > 1
        text: Controllers.count
    }

    Ui.Popup {
        id: popup

        anchorItem: root
        barScreen: root.barScreen
        cardWidth: 320

        Ui.SectionLabel {
            text: "Controllers"
        }

        Ui.PopupRow {
            interactive: false
            visible: Controllers.count === 0
            text: "No controllers"
        }

        Repeater {
            // Keyed on the pad, so a battery tick updates a row in place and
            // only a pad coming or going builds or drops one.
            model: ScriptModel {
                objectProp: "key"
                values: Controllers.devices
            }

            Ui.PopupRow {
                required property var modelData

                interactive: false
                glyph: modelData.transport === "Bluetooth" ? "bluetooth_connected" : "usb"
                text: modelData.name
                detail: Controllers.batteryText(modelData)
            }
        }
    }

    Ui.PopupIpc {
        target: "controller"
        enabled: root.primary
    }
}
