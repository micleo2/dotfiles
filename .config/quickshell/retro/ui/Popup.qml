pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// A dropdown panel anchored under a bar chip.
//
// This cannot be a PopupWindow. The bar sits on WlrLayer.Bottom, so anything
// parented to it renders *behind* application windows. The popup is instead
// its own Overlay surface, exactly the size of the card, placed under the chip.
//
// Outside clicks are detected the only way a Wayland client can: by asking
// the compositor. A HyprlandFocusGrab whitelists this window and the bar it
// hangs from; a press anywhere else clears the grab and closes the popup,
// while the bar keeps native hover, cursor shapes and clicks, so the next
// chip over opens its own popup on the first click.
Scope {
    id: root

    required property Item anchorItem
    required property var barScreen

    // Distance below the chip.
    property int gap: 6

    property int cardWidth: 340
    property int maxCardHeight: 560
    // Hard offset drop shadow, the System 7 kind: the frame's silhouette
    // pushed down and right, no blur. 0 turns it off.
    property int shadowOffset: 4
    // Right-hand chips read better right-aligned to their own edge.
    property bool alignRight: true

    readonly property bool opened: Popups.active === root

    // One highlight per popup, owned here rather than by any row. Controls opt
    // in by setting `rowKey` and binding `cursorKey` to this — see PopupRow.
    // The keyboard moves the same cursor, so hover and keys never disagree.
    property string cursorKey: ""

    onOpenedChanged: {
        if (!root.opened)
            root.cursorKey = "";
    }

    default property alias content: cardContent.data

    // The bar window the chip lives in, for the focus grab.
    readonly property var barWindow: root.anchorItem ? root.anchorItem.QsWindow.window : null

    // mapToItem is not reactive, so the anchor is resolved each time the popup
    // opens rather than bound. Chips only move on a text-size change, which
    // closes the popup anyway. The bar window sits at the screen's top-left,
    // so its coordinates are screen coordinates for our purposes.
    property real anchorX: 0
    property real anchorWidth: 0

    // Card x on screen. The window is placed here (less the border bleed),
    // clamped so the card never runs off either edge.
    readonly property real cardX: {
        var raw = root.alignRight ? root.anchorX + root.anchorWidth - root.cardWidth : root.anchorX;
        var screenWidth = root.barScreen ? root.barScreen.width : raw + root.cardWidth + 8;
        return Math.max(8, Math.min(raw, screenWidth - root.cardWidth - 8));
    }

    function open() {
        if (root.anchorItem) {
            root.anchorX = root.anchorItem.mapToItem(null, 0, 0).x;
            root.anchorWidth = root.anchorItem.width;
        }
        Popups.active = root;
    }

    function close() {
        if (root.opened)
            Popups.active = null;
    }

    function toggle() {
        if (root.opened)
            root.close();
        else
            root.open();
    }

    // Open with the cursor on the first control, for the SUPER+T submap.
    // Deferred one tick so Repeater delegates exist before the first walk.
    function openWithCursor() {
        root.open();
        Qt.callLater(function () {
            root.cursorKey = "";
            root.moveCursor(1);
        });
    }

    // Keyboard cursor.
    //
    // A control is navigable when it carries a non-empty `rowKey`, is visible
    // and enabled, and does not set `navigable: false`. It may offer
    // `activate()`, `adjust(delta)` and `secondary()`. Nothing registers: the
    // content is walked in tree order, which inside a Column is visual order
    // (Repeater delegates are inserted at the Repeater's own position, nested
    // Columns included), and recursion stops at the first navigable item.
    function navigables() {
        var out = [];
        function walk(item) {
            for (var i = 0; i < item.children.length; i++) {
                var child = item.children[i];
                if (!child.visible)
                    continue;
                if (child.rowKey !== undefined && child.rowKey !== "" && child.enabled && child.navigable !== false) {
                    out.push(child);
                    continue;
                }
                walk(child);
            }
        }
        walk(cardContent);
        return out;
    }

    function cursorIndex(items) {
        for (var i = 0; i < items.length; i++) {
            if (items[i].rowKey === root.cursorKey)
                return i;
        }
        return -1;
    }

    function cursorItem() {
        var items = root.navigables();
        var at = root.cursorIndex(items);
        return at < 0 ? null : items[at];
    }

    // delta is ±1 for a step and ±Infinity for an end. No wrap, like vim.
    function moveCursor(delta) {
        var items = root.navigables();
        if (items.length === 0)
            return;
        var at = root.cursorIndex(items);
        var next = at < 0 ? (delta > 0 ? 0 : items.length - 1) : Math.max(0, Math.min(items.length - 1, at + delta));
        root.cursorKey = items[next].rowKey;
        root.reveal(items[next]);
    }

    function activateCursor() {
        var item = root.cursorItem();
        if (item && item.activate)
            item.activate();
    }

    function adjustCursor(delta) {
        var item = root.cursorItem();
        if (item && item.adjust)
            item.adjust(delta);
    }

    function secondaryCursor() {
        var item = root.cursorItem();
        if (item && item.secondary)
            item.secondary();
    }

    // Scroll so `item` sits fully inside the card.
    function reveal(item) {
        // Before the window has laid out the Flickable has no height, and any
        // adjustment would leave the list scrolled by a phantom amount.
        if (flick.height <= 0)
            return;
        var top = item.mapToItem(cardContent, 0, 0).y;
        var bottom = top + item.height;
        var maxY = Math.max(0, flick.contentHeight - flick.height);
        if (top < flick.contentY)
            flick.contentY = Math.max(0, top);
        else if (bottom > flick.contentY + flick.height)
            flick.contentY = Math.min(maxY, bottom - flick.height);
    }

    // Pull the keyboard back from a text field (wifi passphrase) to the list.
    function reclaimFocus() {
        card.forceActiveFocus();
    }

    PanelWindow { // qmllint disable uncreatable-type
        id: win

        visible: root.opened
        screen: root.barScreen

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-retro-popup"
        // On demand, never exclusive: Hyprland routes *all* pointer input to
        // an exclusive layer while one exists, which is what made the bar
        // unclickable under the popup. On-demand layers get keyboard focus
        // when they map, and the grab below keeps it there.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        exclusiveZone: 0
        color: "transparent"

        // Just the card plus its 2px border bleed. Anchored top-left and inset
        // past the bar's exclusive zone, so the top margin is below the bar.
        anchors {
            top: true
            left: true
        }
        // PanelWindow's margins group is not described in Quickshell's type
        // information, so qmllint cannot see it; it works at runtime.
        // qmllint disable unqualified unresolved-type
        margins {
            top: root.gap
            left: root.cardX - 2
        }
        // qmllint enable unqualified unresolved-type
        implicitWidth: root.cardWidth + 4 + root.shadowOffset
        implicitHeight: card.height + 4 + root.shadowOffset

        HyprlandFocusGrab {
            active: root.opened
            windows: root.barWindow ? [win, root.barWindow] : [win]
            onCleared: root.close()
        }

        Rectangle {
            id: shadow

            visible: root.shadowOffset > 0
            x: card.x - 2 + root.shadowOffset
            y: card.y - 2 + root.shadowOffset
            width: card.width + 4
            height: card.height + 4
            color: Config.colors.outline
        }

        Item {
            id: card

            x: 2
            y: 2
            width: root.cardWidth
            height: Math.min(cardContent.implicitHeight + 20, root.maxCardHeight)

            Rectangle {
                anchors.fill: parent
                color: Config.colors.base
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                color: "transparent"
                border.width: 2
                border.color: Config.colors.outline
            }

            Flickable {
                id: flick

                anchors.fill: parent
                anchors.margins: 10
                // The scrollbar gutter is reserved whether or not a scrollbar
                // is showing. Sizing it from `scrollTrack.visible` instead would
                // make the content width depend on the content height, which
                // for any wrapping child is a binding loop.
                anchors.rightMargin: 10 + scrollTrack.width + 4

                contentHeight: cardContent.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: cardContent

                    width: parent.width
                    spacing: 6
                }
            }

            // Overflow indicator. Deliberately not grabbable: it reports the
            // position, it does not accept input.
            Rectangle {
                id: scrollTrack

                readonly property real inner: height - 4
                readonly property real thumbHeight: Math.max(24, scrollTrack.inner * flick.visibleArea.heightRatio)
                // yPosition runs 0..(1 - heightRatio), so it has to be
                // renormalised before it can drive travel across the track.
                readonly property real progress: {
                    var span = 1 - flick.visibleArea.heightRatio;
                    return span > 0 ? Math.max(0, Math.min(1, flick.visibleArea.yPosition / span)) : 0;
                }

                visible: flick.contentHeight > flick.height + 1
                width: 10

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 10
                anchors.topMargin: 10
                anchors.bottomMargin: 10

                color: Config.colors.base
                border.width: 2
                border.color: Config.colors.outline

                Rectangle {
                    x: 2
                    y: 2 + (scrollTrack.inner - scrollTrack.thumbHeight) * scrollTrack.progress
                    width: scrollTrack.width - 4
                    height: scrollTrack.thumbHeight
                    color: Config.colors.shadow
                }
            }

            // `card` is a plain Item, not a FocusScope, so `card.activeFocus`
            // is false exactly while a text field inside it holds the keyboard.
            // That single check is the whole list/field arbitration.
            focus: root.opened
            Keys.onPressed: (event) => {
                // Escape always arrives here (TextInput ignores it): from a
                // field it steps back to the list, from the list it closes.
                if (event.key === Qt.Key_Escape) {
                    if (card.activeFocus)
                        root.close();
                    else
                        card.forceActiveFocus();
                    event.accepted = true;
                    return;
                }
                if (!card.activeFocus)
                    return;

                var shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                event.accepted = true;
                switch (event.key) {
                case Qt.Key_J:
                case Qt.Key_Down:
                case Qt.Key_Tab:
                    root.moveCursor(1);
                    break;
                case Qt.Key_K:
                case Qt.Key_Up:
                case Qt.Key_Backtab:
                    root.moveCursor(-1);
                    break;
                case Qt.Key_H:
                case Qt.Key_Left:
                    root.adjustCursor(-1);
                    break;
                case Qt.Key_L:
                case Qt.Key_Right:
                    root.adjustCursor(1);
                    break;
                case Qt.Key_G:
                    root.moveCursor(shift ? Infinity : -Infinity);
                    break;
                case Qt.Key_Home:
                    root.moveCursor(-Infinity);
                    break;
                case Qt.Key_End:
                    root.moveCursor(Infinity);
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_Space:
                    root.activateCursor();
                    break;
                case Qt.Key_Delete:
                    root.secondaryCursor();
                    break;
                default:
                    event.accepted = false;
                }
            }
        }
    }
}
