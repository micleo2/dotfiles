import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

Scope {
    // 1. Define a global state for the bar
    property bool barVisible: true

    // 2. Define the IPC Handler
    IpcHandler {
        target: "topbar" // This is the name used in the terminal
        // Function to toggle the state
        function toggle(): void {
            barVisible = !barVisible;
        }
    }
    // Taskbar variants, we have one taskber per screen.
    Variants {
        model: Quickshell.screens
        Item {
            id: root
            required property var modelData

            PanelWindow {
                id: taskbar
                visible: barVisible
                screen: root.modelData
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: 35

                /*=== Taskbar Background ===*/
                color: Config.colors.base
                Item {
                    id: taskbarBackground
                    anchors.fill: parent
                    NewBorder {
                        commonBorderWidth: 4
                        commonBorder: false
                        lBorderwidth: 10
                        rBorderwidth: 1
                        tBorderwidth: 10
                        bBorderwidth: 1
                        borderColor: Config.colors.shadow
                    }
                    NewBorder {
                        commonBorderWidth: 4
                        commonBorder: false
                        lBorderwidth: 10
                        rBorderwidth: 10
                        tBorderwidth: 1
                        bBorderwidth: 10
                        borderColor: Config.colors.highlight
                    }

                    Rectangle {
                        id: barBackground
                        anchors {
                            fill: parent
                            margins: 0
                        }
                        color: "transparent"
                        radius: 0
                        border.width: 1
                        border.color: Config.colors.outline
                    }
                }

                /*=== Left portion of bar ===*/
                RowLayout {
                    id: left_comp
                    anchors.verticalCenter: parent.verticalCenter
                    layoutDirection: Qt.LeftToRight
                    spacing: 11
                    height: parent.height
                    // Beginning margin
                    Item {
                        Layout.preferredWidth: 0
                    }
                    // Workspaces
                    Item {
                        id: workspaces_container
                        implicitHeight: parent.height - 8
                        implicitWidth: workspaces.width + 5
                        Rectangle {
                            id: background2
                            anchors.fill: workspaces_container
                            anchors.bottomMargin: -2
                            color: "transparent"
                            // dark grey fill
                            Rectangle {
                                anchors.fill: background2
                                border.width: 0
                                color: Config.colors.shadow
                            }
                            // black outline
                            Rectangle {
                                anchors.fill: background2
                                color: "transparent"
                                border.width: 1
                                z: -5
                                anchors.margins: -1
                                anchors.bottomMargin: 1
                            }
                        }
                        Workspaces {
                            id: workspaces
                            anchors.leftMargin: 2
                            anchors.rightMargin: 0
                        }
                    }
                    // Focused window
                    Item {
                        id: focusedwindow_container
                        visible: FocusedWindow.should_show
                        implicitHeight: parent.height - 8
                        implicitWidth: focusedwindow.width + 8
                        Rectangle {
                            id: focusedwindow_decoration
                            anchors.fill: focusedwindow_container
                            anchors.bottomMargin: -2
                            color: "transparent"
                            // dark grey fill
                            Rectangle {
                                anchors.fill: focusedwindow_decoration
                                border.width: 0
                                color: Config.colors.shadow
                            }
                            // black outline
                            Rectangle {
                                anchors.fill: focusedwindow_decoration
                                color: "transparent"
                                border.width: 1
                                z: -5
                                anchors.margins: -1
                                anchors.bottomMargin: 1
                            }
                        }
                        FocusedWindowWidget {
                            id: focusedwindow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                /*=== Clock ===*/
                Item {
                    id: clock_container
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: parent.height - 8
                    width: clock.width + 4
                    Rectangle {
                        id: clockbg
                        anchors.fill: clock_container
                        anchors.bottomMargin: -2
                        Rectangle {
                            anchors.fill: clockbg
                            border.width: 0
                            color: Config.colors.shadow
                        }
                        Rectangle {
                            anchors.fill: clockbg
                            color: "transparent"
                            border.width: 1
                            z: -5
                            anchors.margins: -1
                            anchors.bottomMargin: 1
                        }
                    }
                    ClockWidget {
                        id: clock
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 5
                    }
                }

                /*=== ============================== ===*/

                /*=== System Tray & Background for it ===*/
                Item {
                    id: test
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    height: parent.height - 8
                    width: sysTray.width + 18
                    Rectangle {
                        id: background
                        anchors.fill: test

                        anchors.bottomMargin: -2
                        color: "transparent"
                        Rectangle {
                            anchors.fill: background
                            border.width: 0
                            color: Config.colors.shadow
                        }
                        Rectangle {
                            anchors.fill: background
                            color: "transparent"
                            border.width: 1
                            z: -5
                            anchors.margins: -1
                            anchors.bottomMargin: 1
                        }
                    }
                    SysTray {
                        id: sysTray
                    }
                }
            }
        }
    }
}
