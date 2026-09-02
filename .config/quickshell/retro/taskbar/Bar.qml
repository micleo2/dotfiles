pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

Scope {
    id: barScope
    property bool barVisible: true
    property double topMargin: 8
    property double sideMargin: 8

    IpcHandler {
        target: "topbar"
        function toggle(): void {
            barScope.barVisible = !barScope.barVisible;
        }
    }
    // Taskbar variants, we have one taskber per screen.
    Variants {
        model: Quickshell.screens
        Item {
            id: root
            required property var modelData

            PanelWindow { // qmllint disable uncreatable-type
                id: taskbar
                visible: barScope.barVisible
                screen: root.modelData
                WlrLayershell.layer: WlrLayer.Bottom
                // Nothing on the bar reads keys, and a bar that can take them
                // would steal them from an open popup whenever the pointer
                // crosses it (Hyprland focuses on-demand layers on hover).
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors {
                    top: true
                    left: true
                    right: true
                }
                // Grows with the text-size control. At the default 12px the
                // font is 22 and this is exactly the original 32.
                implicitHeight: Math.max(32, Config.settings.bar.fontSize + 10)

                /*=== Taskbar Background ===*/
                // The bar toggles between an opaque and a fully transparent
                // color at runtime. The surface format is fixed at window
                // creation; a window born opaque has no alpha channel and can
                // never become transparent later, so force the alpha channel.
                surfaceFormat.opaque: false
                color: Settings.barTransparent ? "transparent" : Config.colors.base
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
                MouseArea {
                    id: barClickArea
                    anchors.fill: parent
                    // No cursorShape: the whole bar is clickable for the
                    // transparency toggle, but it is not a button and should
                    // not advertise itself as one under the pointer.
                    onClicked: {
                        // With a popup open, a click on bare bar is a dismiss,
                        // not a request to change the bar.
                        if (Popups.active)
                            Popups.active = null;
                        else
                            Settings.barTransparent = !Settings.barTransparent;
                    }
                }

                /*=== Left portion of bar ===*/
                RowLayout {
                    id: left_comp
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: barScope.sideMargin
                    layoutDirection: Qt.LeftToRight
                    spacing: 11
                    height: parent.height - barScope.topMargin
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
                            taskbarWindow: taskbar
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

                /*=== Center (Clock + Weather) ===*/
                RowLayout {
                    id: center_comp
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 11
                    height: parent.height - barScope.topMargin

                    // Clock
                    Item {
                        id: clock_container
                        implicitHeight: parent.height
                        implicitWidth: clock.width + 4
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

                    // Weather
                    Item {
                        id: weather_container
                        visible: Weather.temp !== ""
                        implicitHeight: parent.height
                        implicitWidth: weatherWidget.width + 8
                        Rectangle {
                            id: weatherbg
                            anchors.fill: weather_container
                            color: "transparent"
                            Rectangle {
                                anchors.fill: weatherbg
                                border.width: 0
                                color: Config.colors.shadow
                            }
                            Rectangle {
                                anchors.fill: weatherbg
                                color: "transparent"
                                border.width: 2
                                anchors.margins: -2
                            }
                        }
                        WeatherWidget {
                            id: weatherWidget
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                /*=== Right portion of bar ===*/
                RowLayout {
                    id: right_comp
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: barScope.sideMargin
                    layoutDirection: Qt.LeftToRight
                    spacing: 11
                    height: parent.height - barScope.topMargin
                    // System Tray
                    Item {
                        id: systray_container
                        // No applets, no box: an invisible item is skipped by
                        // the layout, so the frame goes with it.
                        visible: sysTray.hasItems
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
                            taskbarWindow: taskbar
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Laptop modules (wifi, bluetooth, display, idle, battery).
                    // Which of these appear is decided by per-machine state (see Modules).
                    BarModules {
                        Layout.fillHeight: true
                        taskbarWindow: taskbar
                        barScreen: root.modelData
                        primary: root.modelData === Quickshell.screens[0]
                    }

                    // Volume. Brings its own Chip, so it needs no decoration
                    // wrapper here.
                    VolumeWidget {
                        Layout.fillHeight: true
                        barScreen: root.modelData
                        primary: root.modelData === Quickshell.screens[0]
                    }
                }
            }
        }
    }
}
