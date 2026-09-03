import "../.."
import "../../ui" as Ui
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../../services"

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

    Ui.MarqueeLabel {
        Layout.alignment: Qt.AlignVCenter
        text: FocusedWindow.application_display_name
        // Beyond this the name scrolls in place instead of widening the bar.
        maxWidth: 220
    }

}
