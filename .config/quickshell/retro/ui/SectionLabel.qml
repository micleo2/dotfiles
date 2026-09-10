import QtQuick
import ".."

// A small heading with a rule running to the right edge.
//
// A sub-heading (`sub`) sits inside a section rather than starting one: the
// rule is what makes a heading read as a top-level break, so a sub-heading
// has none, and it is inset and dimmer besides.
Item {
    id: root

    property string text: ""
    property bool sub: false

    implicitWidth: parent ? parent.width : 0
    implicitHeight: label.implicitHeight + 6

    Label {
        id: label

        anchors.left: parent.left
        anchors.leftMargin: root.sub ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        size: Math.round(Config.settings.bar.fontSize * 0.75)
        text: root.text.toUpperCase()
        opacity: root.sub ? 0.5 : 0.7
    }

    Rectangle {
        visible: !root.sub
        anchors.left: label.right
        anchors.leftMargin: 6
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 2
        color: Config.colors.outline
        opacity: 0.4
    }
}
