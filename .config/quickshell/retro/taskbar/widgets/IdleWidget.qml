pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import "../../ui" as Ui
import "../.."
import "../../services"

// The stay-awake toggle. A chip, not a popup — there is nothing to choose.
Item {
    id: root

    required property var barScreen
    required property var taskbarWindow
    // The bar is instantiated per screen; only one of them should hold the lock.
    required property bool primary

    readonly property bool available: Modules.allow("idle", true)

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.available

    IdleInhibitor {
        window: root.taskbarWindow
        enabled: root.primary && Idle.stayAwake
    }

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true
        fillColor: Idle.stayAwake ? Config.colors.urgent : Config.colors.shadow
        onClicked: Idle.toggle()

        Ui.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            opacity: Idle.stayAwake ? 1 : 0.5
            text: "coffee"
        }
    }
}
