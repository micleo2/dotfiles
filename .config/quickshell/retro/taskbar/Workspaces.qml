import ".."
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.I3

RowLayout {
    id: workspaces

    property bool usingHyprland: Hyprland.workspaces.values.length == 0 ? false : true
    property var currentWorkspaces: Hyprland.workspaces.values.filter((w) => {
        return w.monitor.name == taskbar.screen.name && w.id >= 0;
    })

    spacing: 0

    anchors {
        verticalCenter: parent.verticalCenter
        horizontalCenter: parent.horizontalCenter
    }

    Repeater {
        model: parent.currentWorkspaces

        Button {
            id: control

            property int focusedWindowId: 0

            function getColor() {
                if (usingHyprland == true)
                    focusedWindowId = Hyprland.focusedWorkspace.id;
                else
                    focusedWindowId = I3.focusedWorkspace.number;
                if (modelData.urgent) {
                    return Config.colors.urgent;
                } else {
                    if ((usingHyprland && modelData.id == focusedWindowId) || mouse.hovered)
                        return Config.colors.shadow;
                    else if ((usingHyprland == false && modelData.number == focusedWindowId) || mouse.hovered)
                        return Config.colors.shadow;
                }
                return Config.colors.base;
            }

            implicitWidth: 28
            implicitHeight: 24
            padding: 0
            onPressed: (event) => {
                Hyprland.dispatch(`workspace ` + modelData.id);
                event.accepted = true;
            }

            HoverHandler {
                id: mouse

                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                cursorShape: Qt.PointingHandCursor
            }

            contentItem: Text {
                text: modelData.id
                color: Config.colors.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                font {
                    family: mainFont.name
                    pixelSize: Config.settings.bar.fontSize
                }

            }

            background: Rectangle {
                id: bgRect

                color: getColor()

                Rectangle {
                    visible: index > 0
                    width: 2
                    color: Config.colors.outline

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }

                }

            }

        }

    }

}
