import QtQuick
import ".."

// The bar-slot frame: grey fill with a 2px outline bled 2px outward.
//
// Bar.qml repeated this block verbatim for each of its five widgets. It is one
// component now so the module chips do not add five more copies of it.
//
// Content goes into an inner Row, which derives its own implicit size from its
// children — sizing the frame off childrenRect instead would risk a binding loop.
Item {
    id: root

    default property alias content: inner.data
    property int padding: 5
    property int spacing: 5
    property bool interactive: false
    // The border is drawn from the theme rather than the implicit black the
    // original blocks used, so the non-default palettes actually apply.
    property color borderColor: Config.colors.outline
    property color fillColor: Config.colors.shadow

    signal clicked(var mouse)
    signal scrolled(var event)

    implicitWidth: inner.implicitWidth + root.padding * 2
    implicitHeight: parent ? parent.height : 0

    Rectangle {
        anchors.fill: parent
        color: root.fillColor
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        color: "transparent"
        border.width: 2
        border.color: root.borderColor
    }

    Row {
        id: inner

        anchors.centerIn: parent
        spacing: root.spacing
    }

    WheelHandler {
        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            event.accepted = true;
            root.scrolled(event);
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            // Bar.qml's full-width click area toggles bar transparency on any
            // click, so a chip has to swallow its own or every interaction
            // fires that too.
            mouse.accepted = true;
            root.clicked(mouse);
        }
    }
}
