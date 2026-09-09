import QtQuick
import ".."

// A labelled square checkbox.
PopupControl {
    id: root

    property string text: ""
    property bool checked: false

    signal toggled(bool value)

    implicitHeight: 28

    opacity: root.enabled ? 1 : 0.45

    function activate() {
        root.toggled(!root.checked);
    }

    // Left clears, right sets, so h/l read as off/on rather than as a flip.
    function adjust(delta) {
        root.toggled(delta > 0);
    }

    Rectangle {
        anchors.fill: parent
        color: root.hasCursor ? Config.colors.highlight : "transparent"
    }

    Label {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.right: box.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        elide: Text.ElideRight
    }

    CheckBox {
        id: box

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
    }

    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => {
            mouse.accepted = true;
            root.toggled(!root.checked);
        }
    }
}
