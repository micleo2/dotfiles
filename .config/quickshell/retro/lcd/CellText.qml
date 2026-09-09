import QtQuick
import "../ui" as Ui
import ".."

// Text laid on a CharGrid: sized and spaced to the grid's pitch so every
// character lands on its own cell. Placed by cell, `col` from the left or
// aligned right or centred on the row, and `row` from the top.
Ui.Label {
    id: root

    required property CharGrid grid
    property int col: 0
    property int row: 0
    // Text.AlignLeft (at `col`), Text.AlignRight or Text.AlignHCenter.
    property int align: Text.AlignLeft

    // Guarded: a delegate's bindings can run before its `grid` is set.
    x: {
        if (!root.grid)
            return 0;
        if (root.align === Text.AlignRight)
            return (root.grid.columns - root.text.length) * root.grid.cellWidth;
        if (root.align === Text.AlignHCenter)
            return Math.floor((root.grid.columns - root.text.length) / 2) * root.grid.cellWidth;
        return root.col * root.grid.cellWidth;
    }
    y: root.grid ? root.grid.rowY(root.row) : 0
    height: root.grid ? root.grid.cellHeight : 0
    size: root.grid ? root.grid.size : Config.settings.bar.fontSize
    font.letterSpacing: root.grid ? root.grid.letterSpacing : 0
    textFormat: Text.PlainText
}
