import Quickshell
import Quickshell.Hyprland
import Quickshell.I3
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

import ".."

RowLayout {
    id: workspaces
    spacing: 3
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    property bool usingHyprland: Hyprland.workspaces.values.length == 0 ? false : true

    property var currentWorkspaces: Hyprland.workspaces.values.filter(w => w.monitor.name == taskbar.screen.name && w.id >= 0)

    Repeater {
        model: parent.currentWorkspaces
        Button {
            id: control
            anchors.centerIn: parent.centerIn
            contentItem: Text {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData.id
                font.family: fontMonaco.name
                width: 10
                height: 10
                font.pixelSize: Config.settings.bar.fontSize
                color: Config.colors.text
            }
            onPressed: event => {
                Hyprland.dispatch(`workspace ` + modelData.id);
                event.accepted = true;
            }
            NewBorder {
                commonBorderWidth: 2
                commonBorder: false
                lBorderwidth: -2
                rBorderwidth: 0
                tBorderwidth: -4
                bBorderwidth: -1
                borderColor: Config.colors.outline
                zValue: -1
            }

            // TODO: Improve this, it's very messy right now.
            property int focusedWindowId: 0
            function getColor() {
                if (usingHyprland == true) {
                    focusedWindowId = Hyprland.focusedWorkspace.id;
                } else {
                    focusedWindowId = I3.focusedWorkspace.number;
                }

                if (modelData.urgent) {
                    return Config.colors.urgent;
                } else {
                    if ((usingHyprland && modelData.id == focusedWindowId) || mouse.hovered) {
                        return Config.colors.shadow;
                    } else if ((usingHyprland == false && modelData.number == focusedWindowId) || mouse.hovered) {
                        return Config.colors.shadow;
                    }
                }
                return Config.colors.base;
            }
            background: Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                border.width: 1
                border.color: Config.colors.outline
                width: 22
                height: 22
                color: getColor()
            }

            HoverHandler {
                id: mouse
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
