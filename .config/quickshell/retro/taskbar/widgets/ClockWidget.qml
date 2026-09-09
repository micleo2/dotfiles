import "../.."
import "../../ui" as Ui
import QtQuick
import "../../services"

Item {
    id: root

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        padding: 2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.time
            color: Config.colors.text
            font.pixelSize: Config.settings.bar.fontSize
            font.family: Config.mainFont
        }
    }
}
