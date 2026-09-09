import QtQuick
import ".."

// The bar-slot frame: grey fill with a 2px outline bled 2px outward, and a
// hard 2px drop shadow below and to the right of that, System 7 style. Every
// bar widget is one of these; a widget's popup and IPC handler sit inside
// it too, being non-visual, and only its glyphs and labels are drawn.
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
    property color shadowColor: Config.colors.dropShadow

    // While a button is held, the face shifts onto its shadow, so it reads as
    // pushed in rather than merely highlighted.
    readonly property bool pressed: press.pressed

    signal clicked(var mouse)
    // One per wheel detent, direction +1 or -1. Touchpads send a stream of
    // sub-notch deltas rather than one event per detent, so the remainder is
    // carried between events or a slow drag does nothing and a fast one jumps.
    signal stepped(int direction)
    property real wheelAccumulator: 0

    implicitWidth: inner.implicitWidth + root.padding * 2
    implicitHeight: parent ? parent.height : 0

    // The frame's silhouette two pixels down and right; the border bleeds 2px
    // past the face, so the shadow covers that too. Hidden while pressed, when
    // the face has sunk onto it.
    Shadow {
        visible: !root.pressed
        offset: 2
        bleed: 2
        color: root.shadowColor
    }

    Item {
        id: face

        x: root.pressed ? 2 : 0
        y: root.pressed ? 2 : 0
        width: root.width
        height: root.height

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
    }

    WheelHandler {
        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            event.accepted = true;
            var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
            // One detent is 120 units. Clamp so a flung touchpad cannot
            // deliver a single enormous event.
            root.wheelAccumulator += Math.max(-120, Math.min(120, delta));
            while (Math.abs(root.wheelAccumulator) >= 120) {
                var direction = root.wheelAccumulator > 0 ? 1 : -1;
                root.wheelAccumulator -= direction * 120;
                root.stepped(direction);
            }
        }
    }

    // The cursor lives on a hover handler rather than on the MouseArea below:
    // a disabled MouseArea still owns the cursor under it, so a passive chip
    // (clock, focused window) would advertise a click it cannot take. A
    // disabled handler sets nothing, which also leaves inner controls such as
    // workspace cells and tray icons free to set their own.
    HoverHandler {
        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        id: press

        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            // taskbar/Bar.qml's full-width click area toggles bar transparency on any
            // click, so a chip has to swallow its own or every interaction
            // fires that too.
            mouse.accepted = true;
            root.clicked(mouse);
        }
    }
}
