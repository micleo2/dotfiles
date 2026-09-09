import QtQuick
import ".."

// One lit cell on a CharGrid's mark layer: the block a cursor, a sweep or
// a keystroke echo is drawn with. Fills the cell short of its gutter.
Rectangle {
    id: root

    required property CharGrid grid
    property int col: 0
    property int row: 0

    // Guarded: a delegate's bindings can run before its `grid` is set.
    x: root.grid ? root.col * root.grid.cellWidth : 0
    y: root.grid ? root.grid.rowY(root.row) : 0
    width: root.grid ? root.grid.cellWidth - 1 : 0
    height: root.grid ? root.grid.cellHeight - 1 : 0
    color: Config.colors.text
}
