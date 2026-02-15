import Quickshell
import Quickshell.Hyprland
import Quickshell.I3
import QtQuick
import QtQuick.Effects
import QtQuick.Controls.Basic
import QtQuick.Layouts

import ".."

RowLayout {
    id: workspaces
    spacing: 0
    anchors {
        verticalCenter: parent.verticalCenter
        horizontalCenter: parent.horizontalCenter
    }

    property bool usingHyprland: Hyprland.workspaces.values.length == 0 ? false : true
    property var currentWorkspaces: Hyprland.workspaces.values.filter(w => w.monitor.name == taskbar.screen.name && w.id >= 0)

    Repeater {
        model: parent.currentWorkspaces
        Button {
            id: control
            implicitWidth: 28

            contentItem: Text {
                text: modelData.id
                font {
                    family: mainFont.name
                    pixelSize: Config.settings.bar.fontSize
                }
                color: Config.colors.text
            }

            onPressed: event => {
                Hyprland.dispatch(`workspace ` + modelData.id);
                event.accepted = true;
            }

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

            background: Item {
                RectangularShadow {
                    anchors.fill: bgRect
                    color: "#FF000000" // Semi-transparent black
                    blur: 0
                    offset.x: 2
                    offset.y: 2
                    // Only show shadow for the active workspace
                    visible: (usingHyprland && modelData.id == focusedWindowId)
                }
                Rectangle {
                    id: bgRect
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    border.width: 1
                    border.color: Config.colors.outline
                    color: getColor()
                }
            }

            HoverHandler {
                id: mouse
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
