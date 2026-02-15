import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Hyprland

import ".."

RowLayout {
    anchors.verticalCenter: parent.verticalCenter
    layoutDirection: Qt.LeftToRight
    spacing: 2
    IconImage {
        source: FocusedWindow.application_icon_path
        implicitHeight: parent.height
        implicitWidth: parent.height
    }
    Text {
        text: FocusedWindow.application_name
        color: Config.colors.text
        font.pixelSize: Config.settings.bar.fontSize
        font.family: fontMonaco.name
    }
}
