pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A stepped slider drawn as discrete blocks, in the register of the segmented
// bucket in osd/LcdOsd.qml rather than as a smooth track.
Item {
    id: root

    // Discrete stops. Values may be any numbers; the slider snaps between them.
    property var stops: []
    property int index: 0

    // Keyboard/hover cursor, on the same terms as PopupRow: set `rowKey` and
    // bind `cursorKey` to the popup's to take part.
    property string rowKey: ""
    property string cursorKey: ""
    readonly property bool hasCursor: root.rowKey !== "" && root.rowKey === root.cursorKey

    signal moved(int index)
    signal cursorEntered

    implicitWidth: parent ? parent.width : 0
    implicitHeight: 26

    function indexAt(px) {
        if (root.stops.length === 0)
            return 0;
        var slot = Math.floor(px / (root.width / root.stops.length));
        return Math.max(0, Math.min(root.stops.length - 1, slot));
    }

    function adjust(delta) {
        if (root.stops.length === 0)
            return;
        root.moved(Math.max(0, Math.min(root.stops.length - 1, root.index + delta)));
    }

    // The blocks carry their own borders, so the cursor is a frame around the
    // whole track rather than a recolour of the level.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        color: "transparent"
        border.width: 2
        border.color: root.hasCursor ? Config.colors.highlight : "transparent"
    }

    Row {
        anchors.fill: parent
        spacing: 3

        Repeater {
            model: root.stops.length

            Rectangle {
                required property int index

                width: (root.width - (root.stops.length - 1) * 3) / Math.max(1, root.stops.length)
                height: root.height
                color: index <= root.index ? Config.colors.text : "transparent"
                border.width: 2
                border.color: Config.colors.outline
            }
        }
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
        onPressed: (mouse) => {
            mouse.accepted = true;
            root.moved(root.indexAt(mouse.x));
        }
        onPositionChanged: (mouse) => {
            if (pressed)
                root.moved(root.indexAt(mouse.x));
        }
    }
}
