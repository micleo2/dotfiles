import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

Scope {
    property bool barVisible: true
    property double topMargin: 8
    property double sideMargin: 8

    IpcHandler {
        target: "topbar"
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
                implicitHeight: 32

                /*=== Taskbar Background ===*/
                color: Config.colors.base
                Item {
                    id: taskbarBackground
                    anchors.fill: parent
                    Rectangle {
                        id: barBackground
                        anchors {
                            fill: parent
                            margins: 0
                        }
                        color: "transparent"
                        radius: 0
                    }
                }

                /*=== Left portion of bar ===*/
                RowLayout {
                    id: left_comp
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: sideMargin
                    layoutDirection: Qt.LeftToRight
                    spacing: 11
                    height: parent.height - topMargin
                    // Workspaces
                    Item {
                        id: workspaces_container
                        implicitHeight: parent.height
                        implicitWidth: workspaces.width
                        Rectangle {
                            id: background2
                            anchors.fill: workspaces_container
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
                                border.width: 2
                                anchors.margins: -2
                            }
                        }
                        Workspaces {
                            id: workspaces
                        }
                    }
                    // Focused window
                    Item {
                        id: focusedwindow_container
                        visible: FocusedWindow.should_show
                        implicitHeight: parent.height
                        implicitWidth: focusedwindow.width + 8
                        Rectangle {
                            id: focusedwindow_decoration
                            anchors.fill: focusedwindow_container
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
                                border.width: 2
                                anchors.margins: -2
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
                    height: parent.height - topMargin
                    width: clock.width + 4
                    Rectangle {
                        id: clockbg
                        anchors.fill: clock_container
                        Rectangle {
                            anchors.fill: clockbg
                            border.width: 0
                            color: Config.colors.shadow
                        }
                        Rectangle {
                            anchors.fill: clockbg
                            color: "transparent"
                            border.width: 2
                            anchors.margins: -2
                        }
                    }
                    ClockWidget {
                        id: clock
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 5
                    }
                }

                /*=== Right portion of bar ===*/
                RowLayout {
                    id: right_comp
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: sideMargin
                    layoutDirection: Qt.LeftToRight
                    spacing: 11
                    height: parent.height - topMargin
                    // System Tray
                    Item {
                        id: systray_container
                        implicitHeight: parent.height
                        implicitWidth: sysTray.width + 12
                        Rectangle {
                            id: systraybg
                            anchors.fill: systray_container
                            color: "transparent"
                            Rectangle {
                                anchors.fill: systraybg
                                border.width: 0
                                color: Config.colors.shadow
                            }
                            Rectangle {
                                anchors.fill: systraybg
                                color: "transparent"
                                border.width: 2
                                anchors.margins: -2
                            }
                        }
                        SysTray {
                            id: sysTray
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Volume
                    Item {
                        id: volume_container
                        implicitHeight: parent.height
                        implicitWidth: volumeWidget.width + 4
                        Rectangle {
                            id: volumebg
                            anchors.fill: volume_container
                            Rectangle {
                                anchors.fill: volumebg
                                border.width: 0
                                color: Config.colors.shadow
                            }
                            Rectangle {
                                anchors.fill: volumebg
                                color: "transparent"
                                border.width: 2
                                anchors.margins: -2
                            }
                        }
                        VolumeWidget {
                            id: volumeWidget
                        }
                    }
                }
            }
        }
    }
}
