import QtQuick
import ".."

// A labelled square checkbox.
Item {
    id: root

    property string text: ""
    property bool checked: false

    // Keyboard/hover cursor, on the same terms as PopupRow: set `rowKey` and
    // bind `cursorKey` to the popup's to take part.
    property string rowKey: ""
    property string cursorKey: ""
    readonly property bool hasCursor: root.rowKey !== "" && root.rowKey === root.cursorKey

    signal toggled(bool value)
    signal cursorEntered

    implicitWidth: parent ? parent.width : 0
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

    Rectangle {
        id: box

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        color: root.checked ? Config.colors.text : "transparent"
        border.width: 2
        border.color: Config.colors.outline
    }

    function enter() {
        if (hover.hovered && root.rowKey !== "" && Popups.pointerMoved(hover.point.scenePosition))
            root.cursorEntered();
    }

    HoverHandler {
        id: hover

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        // Enter only, and only on real motion (see Popups.pointerMoved).
        // Leaving deliberately does not clear the cursor, so the highlight
        // stays put when a row slides out from under a still pointer instead
        // of vanishing.
        onHoveredChanged: root.enter()
        onPointChanged: root.enter()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            mouse.accepted = true;
            root.toggled(!root.checked);
        }
    }
}
