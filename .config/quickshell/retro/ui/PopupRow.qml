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

    readonly property bool managed: root.rowKey !== ""

    signal clicked
    signal rightClicked

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
        enabled: root.interactive
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
