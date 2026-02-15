import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Hyprland

import ".."

RowLayout {
    anchors.verticalCenter: parent.verticalCenter
    layoutDirection: Qt.LeftToRight
    spacing: 4
    IconImage {
        visible: FocusedWindow.application_icon_path !== ""
        source: FocusedWindow.application_icon_path
        implicitHeight: parent.height
        implicitWidth: parent.height
        // layer.enabled: true
        layer.effect: MultiEffect {
            saturation: -1
            contrast: 0.7
        }
    }
    Text {
        text: FocusedWindow.application_display_name
        color: Config.colors.text
        font.pixelSize: Config.settings.bar.fontSize
        font.family: mainFont.name
    }
}
