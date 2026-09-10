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

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: Config.settings.bar.iconSlot
        height: Config.settings.bar.iconSlot

        Ui.Label {
            id: iconText

            text: Weather.icon
            size: Math.round(Config.settings.bar.fontSize * 0.9)
            visible: false
        }

        MultiEffect {
            source: iconText
            width: iconText.implicitWidth
            height: iconText.implicitHeight
            anchors.centerIn: parent
            saturation: -1
            contrast: 0.7
        }
    }

    Ui.Label {
        text: Weather.temp
        anchors.verticalCenter: parent.verticalCenter
    }
}
