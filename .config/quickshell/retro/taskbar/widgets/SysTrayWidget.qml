pragma ComponentBehavior: Bound
import "../.."
import "../../ui" as Ui
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Tray applets, monochrome, each with its own menu anchored under it.
Item {
    id: root

    // No applets, no box: the whole slot hides, frame included, so the bar
    // closes up rather than leaving an empty box behind.
    readonly property bool hasItems: SystemTray.items.values.length > 0

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.hasItems

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        padding: 6

        RowLayout {
            id: sysTrayRow

            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                id: sysTray

                model: SystemTray.items

                MouseArea {
                    id: trayItem

                    required property var modelData
                    property SystemTrayItem item: modelData

                    implicitWidth: Config.settings.bar.trayIconSize
                    implicitHeight: Config.settings.bar.trayIconSize
                    onClicked: (event) => {
                        switch (event.button) {
                        case Qt.LeftButton:
                            if (item.hasMenu)
                                menu.open();

                            break;
                        case Qt.RightButton:
                            if (item.hasMenu)
                                menu.open();

                            break;
                        }
                        event.accepted = true;
                    }

                    QsMenuAnchor {
                        id: menu

                        menu: trayItem.item.menu // qmllint disable unresolved-type

                        // Anchor to the icon itself and let Quickshell resolve where it
                        // is. The previous version measured back from the right edge of
                        // the bar, which only lined up while the tray was the last
                        // widget in the row — adding the module chips to its right threw
                        // every menu into the corner.
                        anchor.item: trayItem
                        // Anchor point: the bottom edge of the icon, horizontally
                        // centred on it (leaving Left/Right unset centres that axis).
                        anchor.edges: Edges.Bottom // qmllint disable missing-type
                        // Grow down and to the right of that point, which puts the
                        // menu's top-left corner on the icon's centre line — how
                        // Windows and macOS drop their tray menus.
                        anchor.gravity: Edges.Bottom | Edges.Right // qmllint disable missing-type
                        // Slide back onto the screen near the edges instead of flipping
                        // to the other side of the icon.
                        anchor.adjustment: PopupAdjustment.Slide // qmllint disable missing-type
                    }

                    IconImage {
                        id: trayIcon

                        source: trayItem.item.icon
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        visible: false
                    }

                    Loader {
                        anchors.fill: trayIcon

                        sourceComponent: MultiEffect {
                            source: trayIcon
                            saturation: Config.settings.bar.monochromeTrayIcons ? -1 : 0
                            contrast: Config.settings.bar.monochromeTrayIcons ? 0.7 : 0
                            opacity: mouse.hovered || menu.visible ? 1 : 0.7
                            blurEnabled: false
                            shadowEnabled: true
                            shadowBlur: 0
                            blurMax: 1
                            shadowScale: 1
                            shadowVerticalOffset: 1
                            shadowHorizontalOffset: 1
                            shadowOpacity: 1
                            shadowColor: Config.colors.dropShadow
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
    }
}
