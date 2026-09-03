pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A pixel map drawn as an LCD matrix: '#' cells are lit, every other cell is
// a ghost, and a one-pixel gutter between cells shows the grid.
Item {
    id: root

    property var rows: []
    property int cell: 6
    property real ghost: 0.12
    property color color: Config.colors.text

    readonly property int columns: root.rows.length > 0 ? root.rows[0].length : 0

    implicitWidth: root.columns * root.cell
    implicitHeight: root.rows.length * root.cell

    Repeater {
        model: root.rows.length * root.columns

        Rectangle {
            required property int index

            readonly property int row: Math.floor(index / root.columns)
            readonly property int col: index % root.columns

            x: col * root.cell
            y: row * root.cell
            width: root.cell - 1
            height: root.cell - 1
            color: root.color
            opacity: root.rows[row].charAt(col) === "#" ? 1 : root.ghost
        }
    }
}
