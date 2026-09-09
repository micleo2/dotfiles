import "../.."
import "../../ui" as Ui
import QtQuick
import QtQuick.Effects
import "../../services"

// Condition glyph and temperature. Hidden, frame and all, until the first
// forecast arrives.
Item {
    id: root

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: Weather.temp !== ""

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        padding: 4

        Row {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: iconText

                text: Weather.icon
                color: Config.colors.text
                font.pixelSize: Math.round(Config.settings.bar.fontSize * 0.9)
                font.family: Config.mainFont
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

            Text {
                text: Weather.temp
                color: Config.colors.text
                font.pixelSize: Config.settings.bar.fontSize
                font.family: Config.mainFont
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
