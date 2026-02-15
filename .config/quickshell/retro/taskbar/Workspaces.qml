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
            Layout.fillHeight: true
            implicitWidth: 32
            padding: 0

            contentItem: Text {
                text: modelData.id
                font {
                    family: mainFont.name
                    pixelSize: Config.settings.bar.fontSize
                }
                color: Config.colors.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
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

            background: Rectangle {
                id: bgRect
                color: getColor()
                Rectangle {
                    visible: index > 0
                    width: 2
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }
                    color: Config.colors.outline
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
