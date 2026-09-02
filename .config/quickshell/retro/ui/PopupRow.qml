import QtQuick
import ".."

// One selectable line in a popup: leading glyph, label, trailing status.
Item {
    id: root

    property string glyph: ""
    property string text: ""
    property string detail: ""
    property string trailingGlyph: ""
    property bool selected: false
    property bool busy: false
    // Rows that are pure readouts take no hover, no cursor and no clicks.
    property bool interactive: true

    // Managed-cursor mode, for lists that churn while they are open.
    //
    // A Repeater fed a fresh JS array destroys and recreates every delegate, so
    // a row that paints its own hover blinks each time the model is rebuilt —
    // which, during a bluetooth scan, is many times a second. Omarchy's answer
    // is that the highlight must not live in the delegate at all: rows paint
    // from a cursor the panel owns, and hover only *writes* it. Give a row a
    // `rowKey` and bind `cursorKey` to opt in; leave `rowKey` empty and the row
    // keeps its own hover, which is fine for lists that never move.
    property string rowKey: ""
    property string cursorKey: ""
    readonly property bool managed: root.rowKey !== ""
    readonly property bool hasCursor: root.managed && root.rowKey === root.cursorKey
    // Readouts are skipped by the popup's keyboard cursor even if keyed.
    readonly property bool navigable: root.interactive

    signal clicked
    signal rightClicked
    signal cursorEntered

    implicitWidth: parent ? parent.width : 0
    implicitHeight: Math.max(28, label.implicitHeight + 10)

    // Keyboard entry points, dispatched by Popup on the row under its cursor.
    function activate() {
        root.clicked();
    }

    function secondary() {
        root.rightClicked();
    }

    function enter() {
        if (hover.hovered && root.managed && Popups.pointerMoved(hover.point.scenePosition))
            root.cursorEntered();
    }

    Rectangle {
        anchors.fill: parent
        color: {
            if (!root.interactive)
                return "transparent";
            var lit = root.managed ? root.hasCursor : hover.hovered;
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

        // Selection marker, constructed exactly like PopupToggle's checked box
        // and aligned to the same right edge, so "this one is on" looks the same
        // whether it is a toggle or a row. Filling the row background instead
        // would collide with hover, which is what that background means.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.selected
            width: 18
            height: 18
            color: Config.colors.text
            border.width: 2
            border.color: Config.colors.outline
        }
    }

    HoverHandler {
        id: hover

        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        cursorShape: Qt.PointingHandCursor

        // Enter only, and only on real motion (see Popups.pointerMoved).
        // Leaving deliberately does not clear the cursor, so the highlight
        // stays put when a row slides out from under a still pointer instead
        // of vanishing.
        onHoveredChanged: root.enter()
        onPointChanged: root.enter()
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
