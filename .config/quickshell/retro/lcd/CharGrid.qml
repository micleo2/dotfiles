pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A character LCD module: a fixed grid of ghost cells, one per monospace
// character, that text is laid over. The cell pitch comes from the pixel
// font's own advance, so a glyph lands exactly on its cell; the one-pixel
// gutter between cells is what shows the grid.
//
// Children go into the text layer above the cells. Rows are addressed with
// rowY(n), and text should be sized with `size` and spaced with
// `letterSpacing` so it stays on the pitch. The text layer is nudged left
// by the font's side bearing so ink sits centred on its cell; anything that
// should sit on a cell itself (a lit cell, a cursor block) goes in `marks`,
// which is not nudged.
Item {
    id: root

    property int columns: 28
    property int rows: 2
    property int size: Config.settings.bar.fontSize
    property color color: Config.colors.text
    property real ghost: 0.12
    // Every cell lit: the power-on blink, run once when the module appears.
    property bool flash: false
    property bool flashOnCreate: true

    default property alias content: overlay.data
    property alias marks: marksLayer.data

    // Row pitch from the font's line height.
    FontMetrics {
        id: metrics

        font.family: Config.mainFont
        font.pixelSize: root.size
    }

    // Column pitch from one glyph's advance. This is a TextMetrics rather
    // than FontMetrics.advanceWidth(): that is a method call, which a binding
    // runs once at creation and never again, so a grid built before the
    // font had loaded kept the fallback font's pitch for good and its text
    // walked off the cells. TextMetrics.advanceWidth is a property and
    // follows the font.
    TextMetrics {
        id: glyph

        font.family: Config.mainFont
        font.pixelSize: root.size
        text: "M"
    }

    readonly property real advance: glyph.advanceWidth
    // Cozette carries a one-pixel left bearing and none on the right, so a
    // glyph drawn at its cell's origin lands off-centre. How far left the
    // text layer moves so the ink is centred in the drawn cell.
    readonly property real inkShift: glyph.tightBoundingRect.x - ((root.cellWidth - 1) - glyph.tightBoundingRect.width) / 2
    readonly property real cellWidth: Math.max(1, Math.round(root.advance))
    readonly property real cellHeight: Math.max(1, Math.ceil(metrics.height))
    // Pads a fractional advance out to the integer cell.
    readonly property real letterSpacing: root.cellWidth - root.advance

    implicitWidth: root.columns * root.cellWidth
    implicitHeight: root.rows * root.cellHeight

    function rowY(row) {
        return row * root.cellHeight;
    }

    Repeater {
        model: root.rows * root.columns

        Rectangle {
            required property int index

            x: (index % root.columns) * root.cellWidth
            y: Math.floor(index / root.columns) * root.cellHeight
            width: root.cellWidth - 1
            height: root.cellHeight - 1
            color: root.color
            opacity: root.flash ? 1 : root.ghost
        }
    }

    Item {
        id: marksLayer

        anchors.fill: parent
    }

    Item {
        id: overlay

        x: -root.inkShift
        y: 0
        width: parent.width
        height: parent.height
    }

    Component.onCompleted: {
        if (root.flashOnCreate)
            root.flash = true;
    }

    Timer {
        running: root.flash
        interval: 70
        onTriggered: root.flash = false
    }
}
