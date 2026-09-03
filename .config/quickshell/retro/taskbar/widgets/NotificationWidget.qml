pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import "../../ui" as Ui
import "../.."
import "../../services"
import "../../notifications"

// The bell: do-not-disturb state and the count of what has come and gone,
// with a popup holding the switch and the history. Right-clicking the chip
// toggles silencing without opening anything.
Item {
    id: root

    required property var barScreen
    required property bool primary

    // On by default everywhere; "notifications": false in settings.json hides
    // it. (Modules.allow would read the default as laptop-only.)
    readonly property bool available: Modules.setting("notifications") !== false
    readonly property int count: Notifications.history.length

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.available

    function glyph() {
        if (Notifications.doNotDisturb)
            return "notifications_off";
        return root.count > 0 ? "notifications_active" : "notifications";
    }

    function urgencyGlyph(urgency) {
        if (urgency === NotificationUrgency.Critical)
            return "warning";
        return urgency === NotificationUrgency.Low ? "info" : "mail";
    }

    Component.onCompleted: {
        if (root.primary)
            Notifications.panel = popup;
    }

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true
        fillColor: Notifications.doNotDisturb ? Config.colors.urgent : Config.colors.shadow
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                Notifications.toggleDoNotDisturb();
            else
                popup.toggle();
        }

        Ui.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph()
        }

        Ui.Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.count > 0
            text: root.count
        }
    }

    Ui.Popup {
        id: popup

        anchorItem: chip
        barScreen: root.barScreen
        cardWidth: 360

        Ui.SectionLabel {
            text: "Notifications"
        }

        Ui.PopupToggle {
            rowKey: "dnd"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "dnd"

            text: "Do not disturb"
            checked: Notifications.doNotDisturb
            onToggled: (value) => Notifications.setDoNotDisturb(value)
        }

        Ui.PopupRow {
            rowKey: "dismiss"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "dismiss"

            visible: Notifications.popups.length > 0
            glyph: "close"
            text: "Dismiss all"
            detail: Notifications.popups.length
            onClicked: Notifications.dismissAll()
        }

        Ui.SectionLabel {
            text: "History"
        }

        Ui.PopupRow {
            interactive: false
            visible: root.count === 0
            text: "Nothing yet"
        }

        Repeater {
            model: Notifications.history

            // Click or Enter drops the entry; right click too.
            Ui.PopupRow {
                required property var modelData
                required property int index

                rowKey: "h:" + modelData.key
                cursorKey: popup.cursorKey
                onCursorEntered: popup.cursorKey = "h:" + modelData.key

                glyph: root.urgencyGlyph(modelData.urgency)
                text: modelData.summary !== "" ? modelData.summary : modelData.body
                detail: modelData.appName + " " + modelData.time
                onClicked: Notifications.forgetHistory(index)
                onRightClicked: Notifications.forgetHistory(index)
            }
        }

        Ui.PopupRow {
            rowKey: "clear"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "clear"

            visible: root.count > 0
            glyph: "delete"
            text: "Clear history"
            onClicked: Notifications.clearHistory()
        }
    }
}
