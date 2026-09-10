import QtQuick
import ".."

// What every control in a popup shares: the card's width, and a place in
// the popup's cursor.
//
// One highlight per popup, owned by the Popup rather than by any control.
// A Repeater fed a fresh JS array destroys and recreates every delegate, so
// a control that painted its own hover would blink each time the model was
// rebuilt, which during a bluetooth scan is many times a second. Instead a
// control opts in by setting `rowKey`; hover only *writes* the popup's
// cursor, the keyboard moves the same cursor, and `hasCursor` is what the
// control paints from, so hover and keys never disagree. Leave `rowKey`
// empty and the control takes no part.
Item {
    id: root

    property string rowKey: ""
    // Cleared by controls that are readouts: the keyboard cursor skips them.
    property bool navigable: true
    // The Popup this sits in, found up the tree once it is built (the card
    // content carries it; see Popup).
    property var popup: null

    readonly property bool hasCursor: root.rowKey !== "" && root.popup !== null && root.popup.cursorKey === root.rowKey
    readonly property alias hovered: hover.hovered
    property alias hoverEnabled: hover.enabled

    implicitWidth: parent ? parent.width : 0

    Component.onCompleted: {
        var item = root.parent;
        while (item && item.popup === undefined)
            item = item.parent;
        root.popup = item ? item.popup : null;
    }

    function enter() {
        if (hover.hovered && root.rowKey !== "" && root.popup && Popups.pointerMoved(hover.point.scenePosition))
            root.popup.cursorKey = root.rowKey;
    }

    HoverHandler {
        id: hover

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        // No cursorShape here: a control's MouseArea sits on top and owns an
        // arrow cursor of its own, which would shadow it (see Chip). Each
        // control puts the hand on its MouseArea instead.

        // Enter only, and only on real motion (see Popups.pointerMoved).
        // Leaving deliberately does not clear the cursor, so the highlight
        // stays put when a row slides out from under a still pointer instead
        // of vanishing.
        onHoveredChanged: root.enter()
        onPointChanged: root.enter()
    }
}
