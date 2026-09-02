pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A character LCD module: a fixed grid of ghost cells, one per monospace
// character, that text is laid over. The cell pitch comes from the pixel
// font's own advance, so a glyph lands exactly on its cell; the one-pixel
// gutter between cells is what shows the grid.
//
// Children go into the overlay above the cells. Rows are addressed with
// rowY(n), and text should be sized with `size` and spaced with
// `letterSpacing` so it stays on the pitch.
Item {
    id: root

    property int columns: 28
    property int rows: 2
    property int size: Config.settings.bar.fontSize
    property color color: Config.colors.text
    property real ghost: 0.12
    // Every cell lit: the power-on blink, run once when the module appears.
    property bool flash: false

    default property alias content: overlay.data

    FontMetrics {
        id: metrics

        font.family: Config.mainFont
        font.pixelSize: root.size
    }

    readonly property real advance: metrics.advanceWidth("M")
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
        id: overlay

        anchors.fill: parent
    }

    Component.onCompleted: root.flash = true

    Timer {
        running: root.flash
        interval: 70
        onTriggered: root.flash = false
    }
}
