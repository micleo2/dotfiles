import "../../ui" as Ui
import QtQuick
import "../../services"

Ui.Chip {
    id: root

    Ui.Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Time.time
    }

}
