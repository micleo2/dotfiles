pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."
import "widgets" as Widgets
import "../services"
import "../ui" as Ui

Scope {
    id: barScope
    property bool barVisible: true
    property double topMargin: 8
    // Room under the chips. Their drop shadow reaches 4px below the box, so
    // centering the box alone leaves the shadow flush against the window
    // border when Hyprland gaps are 0, and the window's own shadow darkens
    // the last few px of the bar on top of that. This pads the bottom and
    // the chips are nudged up by half of it to keep the silhouette centered.
    property int bottomPad: 4
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
            // Bars are instantiated per screen; per-screen singletons (IPC
            // targets, the idle inhibitor) are claimed by this one only.
            readonly property bool primary: root.modelData === Quickshell.screens[0]

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
                implicitHeight: Config.settings.bar.height + barScope.bottomPad

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
                // Stay awake's compositor half. It needs a surface to hang
                // from, and it is the bar's rather than the stay-awake chip's
                // so switching that chip off does not quietly let the screen
                // lock while the logind half (Idle) still blocks sleep.
                IdleInhibitor {
                    window: taskbar
                    enabled: root.primary && Idle.stayAwake
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
                        if (Ui.Popups.active)
                            Ui.Popups.active = null;
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
                    height: parent.height - barScope.topMargin - barScope.bottomPad
                    anchors.verticalCenterOffset: -barScope.bottomPad / 2
                    // The switchboard for every other widget; never off itself.
                    Widgets.ControlCenterWidget {
                        Layout.fillHeight: true
                        barScreen: root.modelData
                        primary: root.primary
                    }

                    BarSlot {
                        module: "workspaces"
                        sourceComponent: Widgets.WorkspacesWidget {
                            taskbarWindow: taskbar
                        }
                    }

                    BarSlot {
                        module: "window"
                        sourceComponent: Widgets.FocusedWindowWidget {}
                    }
                }

                /*=== Center (Clock + Weather) ===*/
                RowLayout {
                    id: center_comp
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 11
                    height: parent.height - barScope.topMargin - barScope.bottomPad
                    anchors.verticalCenterOffset: -barScope.bottomPad / 2

                    BarSlot {
                        module: "clock"
                        sourceComponent: Widgets.ClockWidget {}
                    }

                    BarSlot {
                        module: "weather"
                        sourceComponent: Widgets.WeatherWidget {}
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
                    height: parent.height - barScope.topMargin - barScope.bottomPad
                    anchors.verticalCenterOffset: -barScope.bottomPad / 2
                    BarSlot {
                        module: "tray"
                        sourceComponent: Widgets.SysTrayWidget {}
                    }

                    // Laptop modules (wifi, bluetooth, display, idle, battery).
                    // Which of these appear is decided by per-machine state (see Modules).
                    BarModules {
                        Layout.fillHeight: true
                        barScreen: root.modelData
                        primary: root.primary
                    }

                    BarSlot {
                        module: "volume"
                        sourceComponent: Widgets.VolumeWidget {
                            barScreen: root.modelData
                            primary: root.primary
                        }
                    }

                    // Notifications: the bell, silencing, and history.
                    BarSlot {
                        module: "notifications"
                        sourceComponent: Widgets.NotificationWidget {
                            barScreen: root.modelData
                            primary: root.primary
                        }
                    }
                }
            }
        }
    }
}
