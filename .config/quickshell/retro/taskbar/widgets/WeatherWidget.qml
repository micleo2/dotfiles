import "../.."
import "../../ui" as Ui
import QtQuick
import QtQuick.Effects
import "../../services"

// Condition glyph and temperature. Hidden, frame and all, until the first
// forecast arrives.
Ui.Chip {
    id: root

    visible: Weather.temp !== ""

    padding: 4

    Row {
        anchors.verticalCenter: parent.verticalCenter

        Ui.Label {
            id: iconText

            text: Weather.icon
            size: Math.round(Config.settings.bar.fontSize * 0.9)
            anchors.verticalCenter: parent.verticalCenter
            visible: false
        }

        MultiEffect {
            source: iconText
            width: iconText.implicitWidth
            height: iconText.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            saturation: -1
            contrast: 0.7
        }

        Ui.Label {
            text: Weather.temp
            anchors.verticalCenter: parent.verticalCenter
        }
    }

}
