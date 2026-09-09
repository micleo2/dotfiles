pragma ComponentBehavior: Bound
import "../.."
import "../../ui" as Ui
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.I3

// One cell per workspace on this bar's monitor. The cells butt against the
// chip frame with no padding, so the row reads as a segmented button.
Item {
    id: root

    required property var taskbarWindow

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        padding: 0

        RowLayout {
            id: workspaces

            property bool usingHyprland: Hyprland.workspaces.values.length == 0 ? false : true
            property var currentWorkspaces: Hyprland.workspaces.values.filter((w) => {
                return w.monitor.name == root.taskbarWindow.screen.name && w.id >= 0;
            })

            // Fill the face so the cell backgrounds meet the frame whatever
            // the bar's text size.
            height: chip.height
            spacing: 0

            Repeater {
                model: workspaces.currentWorkspaces

                Button {
                    id: control

                    required property var modelData
                    required property int index

                    property int focusedWindowId: 0

                    function getColor() {
                        if (workspaces.usingHyprland == true)
                            focusedWindowId = Hyprland.focusedWorkspace.id;
                        else
                            focusedWindowId = I3.focusedWorkspace.number;
                        if (modelData.urgent) {
                            return Config.colors.urgent;
                        } else {
                            if ((workspaces.usingHyprland && modelData.id == focusedWindowId) || mouse.hovered)
                                return Config.colors.shadow;
                            else if ((workspaces.usingHyprland == false && modelData.number == focusedWindowId) || mouse.hovered)
                                return Config.colors.shadow;
                        }
                        return Config.colors.base;
                    }

                    implicitWidth: 28
                    Layout.fillHeight: true
                    padding: 0
                    onClicked: {
                        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${modelData.id}, on_current_monitor = true })`);
                    }

                    HoverHandler {
                        id: mouse

                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        cursorShape: Qt.PointingHandCursor
                    }

                    contentItem: Text {
                        text: control.modelData.id
                        color: Config.colors.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        font {
                            family: Config.mainFont
                            pixelSize: Config.settings.bar.fontSize
                        }
                    }

                    background: Rectangle {
                        id: bgRect

                        color: control.getColor()

                        Rectangle {
                            visible: control.index > 0
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
    }
}
