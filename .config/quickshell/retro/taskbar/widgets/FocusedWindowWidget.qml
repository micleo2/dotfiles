import "../.."
import "../../ui" as Ui
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../../services"

// The focused window's icon and name. Hidden, frame and all, when there is
// nothing to show.
Ui.Chip {
    id: root

    readonly property bool available: FocusedWindow.should_show

    visible: root.available

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        layoutDirection: Qt.LeftToRight
        spacing: root.spacing

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

}
