pragma ComponentBehavior: Bound

import QtQuick
import "../lcd" as Lcd
import "../ui" as Ui
import ".."
import "../services"

// The keyboard's layout as a Game & Watch LCD module in the OSD's frame:
// hard offset shadow, outlined bezel, dark face. Inside, a header row with
// every layer's name (the shown one lit) and the layer's title, then the
// keys in their real geometry from the keyboard's layout, one ghost cell
// each with its legend lit on top.
//
// A key's cell is five character cells wide and two text rows tall, so a
// legend of up to four characters sits on the top row and what the key does
// when held (a layer, a modifier) on the row below. Transparent keys show
// what they fall through to, ghosted; the key that was held to enter the
// layer is filled and its legend lit in the urgent colour, and so is any
// key held on the board right now while it is talking to the shell.
//
// A wide board (the Svalboard is 25 units across) is drawn in a smaller
// pixel size so it fits the screen it is on, in whole-pixel steps of the
// font so the cells still land on pixels.
//
// Keys while the window is up: Tab, Right, Down and Space go to the next
// layer, Shift+Tab, Left and Up to the previous, 1-9 pick one, B switches
// boards, Escape closes.
Item {
    id: root

    property bool inputEnabled: false
    // The width the module has to fit in, from the window's screen.
    property real maxWidth: 0

    readonly property var shownLayer: Keymap.current
    readonly property var layerKeys: root.shownLayer ? root.shownLayer.keys : []

    readonly property real ghost: 0.12
    readonly property real dim: 0.35
    readonly property int pad: 18
    // The text size the board would take at the bar's size, shrunk until it
    // fits: 5 cells per key unit, so the natural width is roughly
    // units * 5 * advance, plus the frame. Cozette's advance at a pixel size
    // is about half of it.
    readonly property int size: {
        var full = Config.settings.bar.fontSize;
        if (root.maxWidth <= 0 || Keymap.width <= 0)
            return full;
        var frame = 2 * root.pad + 24;
        var natural = Keymap.width * 5 * natural_advance.advanceWidth + frame;
        if (natural <= root.maxWidth)
            return full;
        return Math.max(8, Math.floor(full * (root.maxWidth - frame) / (natural - frame)));
    }

    TextMetrics {
        id: natural_advance

        font.family: Config.mainFont
        font.pixelSize: Config.settings.bar.fontSize
        text: "M"
    }
    readonly property color ink: Config.colors.text
    readonly property color lit: Config.colors.urgent

    // The character cell, from the pixel font's own advance and line
    // height, as CharGrid does it, so legends land on the same pitch as
    // every other LCD module.
    FontMetrics {
        id: metrics

        font.family: Config.mainFont
        font.pixelSize: root.size
    }

    TextMetrics {
        id: glyph

        font.family: Config.mainFont
        font.pixelSize: root.size
        text: "M"
    }

    readonly property real cellWidth: Math.max(1, Math.round(glyph.advanceWidth))
    readonly property real cellHeight: Math.max(1, Math.ceil(metrics.height))
    readonly property real letterSpacing: root.cellWidth - glyph.advanceWidth

    // One key unit: four legend cells plus one of air, two text rows plus
    // a little air. The gap is what shows the grid between keys.
    readonly property real unitW: 5 * root.cellWidth
    readonly property real unitH: 2 * root.cellHeight + 8
    readonly property int gap: 4

    readonly property real boardWidth: Math.max(root.unitW, Keymap.width * root.unitW - root.gap)
    readonly property real boardHeight: Math.max(root.unitH, Keymap.height * root.unitH - root.gap)
    readonly property int columns: Math.max(1, Math.floor(root.boardWidth / root.cellWidth))

    // Where each layer name sits in the header, two cells apart.
    readonly property var nameCells: {
        var out = [];
        var x = 0;
        for (var i = 0; i < Keymap.layers.length; i++) {
            out.push(x);
            x += String(Keymap.layers[i].name).length + 2;
        }
        return out;
    }
    readonly property string title: (Keymap.title + (Keymap.boards.length > 1 ? " [B]" : "") + "  " + (root.shownLayer ? String(root.shownLayer.title) : "NO KEYMAP")).toUpperCase()

    implicitWidth: bezel.width + 4
    implicitHeight: bezel.height + 4

    function focusInput() {
        if (root.inputEnabled)
            input.forceActiveFocus();
    }

    onInputEnabledChanged: {
        if (root.inputEnabled)
            Qt.callLater(root.focusInput);
    }

    Component.onCompleted: Qt.callLater(root.focusInput)

    // The frame language: hard offset shadow, outlined bezel, dark face.
    Rectangle {
        x: bezel.x + 4
        y: bezel.y + 4
        width: bezel.width
        height: bezel.height
        color: Config.colors.dropShadow
    }

    Rectangle {
        id: bezel

        width: panel.implicitWidth + 2 * root.pad
        height: panel.implicitHeight + 2 * root.pad
        color: Config.colors.base
        border.width: 2
        border.color: Config.colors.outline

        // The LCD face.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 8
            color: Config.colors.shadow
            border.width: 2
            border.color: Config.colors.outline
        }

        Column {
            id: panel

            anchors.centerIn: parent
            spacing: 8

            // Header: every layer's name as a ghost, the shown one lit, and
            // the shown layer's title at the right.
            Lcd.CharGrid {
                id: header

                columns: root.columns
                rows: 1
                size: root.size
                ghost: root.ghost

                Repeater {
                    model: Keymap.layers

                    Ui.Label {
                        id: nameLabel

                        required property var modelData
                        required property int index

                        readonly property bool active: index === Keymap.index

                        x: root.nameCells[index] * header.cellWidth
                        y: header.rowY(0)
                        height: header.cellHeight
                        text: String(modelData.name)
                        color: nameLabel.active ? root.lit : root.ink
                        opacity: nameLabel.active ? 1 : root.dim
                        size: header.size
                        font.letterSpacing: header.letterSpacing
                        textFormat: Text.PlainText
                    }
                }

                Ui.Label {
                    x: (header.columns - root.title.length) * header.cellWidth
                    y: header.rowY(0)
                    height: header.cellHeight
                    text: root.title
                    color: root.ink
                    size: header.size
                    font.letterSpacing: header.letterSpacing
                    textFormat: Text.PlainText
                }
            }

            // The keys.
            Item {
                id: board

                width: root.boardWidth
                height: root.boardHeight

                Repeater {
                    model: root.layerKeys

                    Item {
                        id: key

                        required property var modelData

                        readonly property bool trns: modelData.trns === true
                        readonly property bool none: modelData.none === true
                        readonly property bool entry: modelData.entry === true
                        readonly property string matrix: Array.isArray(modelData.matrix) ? modelData.matrix[0] + "," + modelData.matrix[1] : ""
                        readonly property bool down: key.matrix !== "" && Qmk.pressed.indexOf(key.matrix) !== -1
                        readonly property bool lit: key.entry || key.down
                        readonly property string tap: String(modelData.tap || "")
                        readonly property string hold: String(modelData.hold || "")
                        readonly property color legendColor: key.lit ? root.lit : root.ink
                        readonly property real legendOpacity: key.lit ? 1 : (key.trns ? root.dim : 1)

                        x: Number(modelData.x) * root.unitW
                        y: Number(modelData.y) * root.unitH
                        width: Number(modelData.w || 1) * root.unitW - root.gap
                        height: Number(modelData.h || 1) * root.unitH - root.gap

                        // The cell: a ghost like every other segment, filled
                        // in for the entry key.
                        Rectangle {
                            anchors.fill: parent
                            color: root.ink
                            opacity: key.down ? 0.5 : (key.entry ? 0.3 : root.ghost)
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.width: 1
                            border.color: root.ink
                            opacity: key.none ? root.ghost : root.dim
                        }

                        Ui.Label {
                            width: parent.width
                            height: root.cellHeight
                            y: key.hold === "" ? Math.round((parent.height - root.cellHeight) / 2) : 4
                            text: key.tap
                            color: key.legendColor
                            opacity: key.legendOpacity
                            size: root.size
                            font.letterSpacing: root.letterSpacing
                            horizontalAlignment: Text.AlignHCenter
                            textFormat: Text.PlainText
                        }

                        Ui.Label {
                            width: parent.width
                            height: root.cellHeight
                            y: parent.height - root.cellHeight - 4
                            visible: key.hold !== ""
                            text: key.hold
                            color: key.legendColor
                            opacity: key.legendOpacity * 0.6
                            size: root.size
                            font.letterSpacing: root.letterSpacing
                            horizontalAlignment: Text.AlignHCenter
                            textFormat: Text.PlainText
                        }
                    }
                }
            }
        }
    }

    Item {
        id: input

        focus: true

        Keys.onPressed: (event) => {
            var shift = (event.modifiers & Qt.ShiftModifier) !== 0;
            if (event.key === Qt.Key_Escape) {
                Keymap.dismiss();
            } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up || (shift && event.key === Qt.Key_Tab)) {
                Keymap.prev();
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Space) {
                Keymap.next();
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                Keymap.select(event.key - Qt.Key_1);
            } else if (event.key === Qt.Key_B) {
                Keymap.nextBoard();
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.focusInput()
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                Keymap.prev();
            else if (wheel.angleDelta.y < 0)
                Keymap.next();
        }
    }
}
