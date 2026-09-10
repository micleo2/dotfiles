import QtQuick
import ".."

// One selectable line in a popup: leading glyph, label, trailing status.
//
// With a `rowKey` the row paints from the popup's cursor (see PopupControl);
// without one it keeps its own hover, which is fine for lists that never
// move.
PopupControl {
    id: root

    property string glyph: ""
    property string text: ""
    property string detail: ""
    property string trailingGlyph: ""
    property bool selected: false
    property bool busy: false
    // Rows that are pure readouts take no hover, no cursor and no clicks.
    property bool interactive: true
    // An optional trailing action button: a glyph with its own click, drawn
    // between the status and the selection marker. Empty hides it. Set it
    // only while the row has the cursor to keep a list quiet until pointed at.
    property string actionGlyph: ""
    property color actionColor: Config.colors.text

    readonly property bool managed: root.rowKey !== ""

    signal clicked
    signal rightClicked
    signal actionClicked

    // Readouts are skipped by the popup's keyboard cursor even if keyed.
    navigable: root.interactive
    hoverEnabled: root.interactive

    implicitHeight: Math.max(28, label.implicitHeight + 10)

    // Keyboard entry points, dispatched by Popup on the row under its cursor.
    function activate() {
        root.clicked();
    }

    function secondary() {
        root.rightClicked();
    }

    Rectangle {
        anchors.fill: parent
        color: {
            if (!root.interactive)
                return "transparent";
            var lit = root.managed ? root.hasCursor : root.hovered;
            return lit ? Config.colors.highlight : "transparent";
        }
    }

    Glyph {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        visible: root.glyph !== ""
        text: root.glyph
    }

    MarqueeLabel {
        id: label

        anchors.left: icon.visible ? icon.right : parent.left
        anchors.leftMargin: icon.visible ? 6 : 4
        anchors.right: trailing.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        underline: root.busy
    }

    Row {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        // Above the row's own MouseArea, so the action button gets its click.
        z: 1

        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.detail !== ""
            text: root.detail
            size: Math.round(Config.settings.bar.fontSize * 0.8)
            opacity: 0.75
        }

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailingGlyph !== ""
            text: root.trailingGlyph
            size: Math.round(Config.settings.bar.fontSize * 0.85)
            opacity: 0.75
        }

        // The action button. Its hit area is padded past the glyph's ink so
        // it is not a sliver, and the row's click never sees this press.
        // Under the pointer it inverts, glyph on a filled square, so it reads
        // as its own target inside the already-highlighted row.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.actionGlyph !== ""
            width: actionIcon.implicitWidth + 10
            height: 22

            Rectangle {
                anchors.fill: parent
                visible: actionPress.containsMouse
                color: root.actionColor
            }

            Glyph {
                id: actionIcon

                anchors.centerIn: parent
                text: root.actionGlyph
                color: actionPress.containsMouse ? Config.colors.base : root.actionColor
                size: Math.round(Config.settings.bar.fontSize * 0.85)
            }

            MouseArea {
                id: actionPress

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    mouse.accepted = true;
                    root.actionClicked();
                }
            }
        }

        // Selection marker, aligned to the same right edge as PopupToggle's
        // box. Filling the row background instead would collide with hover,
        // which is what that background means.
        CheckBox {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.selected
            checked: true
        }
    }

    MouseArea {
        anchors.fill: parent
        // Hidden rather than disabled: a disabled MouseArea keeps its arrow
        // cursor, but a readout should not show one over a hand-cursor list.
        visible: root.interactive
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            mouse.accepted = true;
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }
}
