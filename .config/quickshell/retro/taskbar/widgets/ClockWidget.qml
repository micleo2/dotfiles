import "../../ui" as Ui
import QtQuick
import "../../services"

Ui.Chip {
    id: root

    readonly property bool available: true

    Ui.Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Time.time
    }

}
