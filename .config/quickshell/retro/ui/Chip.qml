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
    // One per wheel detent, direction +1 or -1 (see WheelSteps).
    signal stepped(int direction)

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

    WheelSteps {
        enabled: root.interactive
        onStepped: (direction) => root.stepped(direction)
    }

    // The hand cursor has to sit on the MouseArea itself. Every MouseArea
    // owns an arrow cursor from birth (Qt calls setCursor in its constructor),
    // and Qt resolves the cursor from the topmost item under the pointer, so
    // a hover handler on the chip is shadowed by this child no matter what
    // it asks for. A passive chip (clock, focused window) must not advertise
    // a click it cannot take, and a merely disabled MouseArea still owns its
    // cursor; hiding it is what takes it out of the lookup, which also leaves
    // inner controls such as workspace cells and tray icons free to set their
    // own.
    MouseArea {
        id: press

        anchors.fill: parent
        visible: root.interactive
        cursorShape: Qt.PointingHandCursor
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
