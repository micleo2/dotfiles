import QtQuick
import ".."

// A small heading with a rule running to the right edge.
Item {
    id: root

    property string text: ""

    implicitWidth: parent ? parent.width : 0
    implicitHeight: label.implicitHeight + 6

    Label {
        id: label

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        size: Math.round(Config.settings.bar.fontSize * 0.75)
        text: root.text.toUpperCase()
        opacity: 0.7
    }

    Rectangle {
        anchors.left: label.right
        anchors.leftMargin: 6
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 2
        color: Config.colors.outline
        opacity: 0.4
    }
}
