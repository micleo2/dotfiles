import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import QtQuick.Effects

import ".."

RowLayout {
    id: sysTrayRow

    Repeater {
        id: sysTray
        model: SystemTray.items

        MouseArea {
            id: trayItem
            property SystemTrayItem item: modelData
            implicitWidth: Config.settings.bar.trayIconSize
            implicitHeight: Config.settings.bar.trayIconSize

            onClicked: event => {
                switch (event.button) {
                case Qt.LeftButton:
                    if (item.hasMenu) {
                        menu.open();
                    }
                    break;
                case Qt.RightButton:
                    if (item.hasMenu) {
                        menu.open();
                    }
                    break;
                }

                event.accepted = true;
            }

            QsMenuAnchor {
                id: menu

                menu: trayItem.item.menu
                anchor.window: taskbar

                // Yes I know, this is a confusing way to get the position for the menu, but that's
                // just how Qt is.
                anchor.rect.x: taskbar.width - (sysTrayRow.width + trayItem.x)
                anchor.rect.y: taskbar.height - 10

                anchor.rect.height: trayItem.height
                anchor.edges: Edges.Bottom
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
                    saturation: Config.settings.bar.monochromeTrayIcons ? -1.0 : 0
                    contrast: Config.settings.bar.monochromeTrayIcons ? 0.7 : 0.0
                    opacity: mouse.hovered || menu.visible ? 1 : 0.7
                    blurEnabled: false
                    shadowEnabled: true

                    shadowBlur: 0
                    blurMax: 1
                    shadowScale: 1
                    shadowVerticalOffset: 1
                    shadowHorizontalOffset: 1
                    shadowOpacity: 1
                    shadowColor: "black"
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
