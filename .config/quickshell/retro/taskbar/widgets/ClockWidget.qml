import "../../ui" as Ui
import QtQuick
import "../../services"

Ui.Chip {
    id: root

    padding: 2

    Ui.Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Time.time
    }

}
