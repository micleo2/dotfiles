pragma ComponentBehavior: Bound

import QtQuick
import "../ui" as Ui
import ".."

// One character-grid row with a prompt, a line being typed and a block
// cursor: the calculator's draft row and the launcher's query row. The
// line is windowed so the cursor always lands on the grid. The cursor is a
// lit cell with the character under it in the face colour, the lock's
// typed-cell language, so it sits on the cell layer rather than the text
// layer. Nothing here takes keys; the owner's TextInput does, and its text
// and cursorPosition are mirrored in.
CharGrid {
    id: root

    property string prompt: "> "
    property string text: ""
    property int cursorPosition: 0
    property color ink: Config.colors.text
    property color face: Config.colors.shadow
    property bool cursorOn: true

    readonly property int avail: Math.max(1, root.columns - root.prompt.length)
    readonly property int cursorPos: Math.max(0, Math.min(root.cursorPosition, root.text.length))
    readonly property int start: root.cursorPos >= root.avail ? root.cursorPos - root.avail + 1 : 0
    readonly property string shown: root.text.substr(root.start, root.avail)
    readonly property int cursorCell: root.prompt.length + root.cursorPos - root.start

    rows: 1

    Ui.Label {
        x: 0
        y: root.rowY(0)
        height: root.cellHeight
        text: root.prompt + root.shown
        color: root.ink
        size: root.size
        font.letterSpacing: root.letterSpacing
        textFormat: Text.PlainText
    }

    marks: Rectangle {
        x: root.cursorCell * root.cellWidth
        y: 0
        width: root.cellWidth - 1
        height: root.cellHeight - 1
        color: root.ink
        visible: root.cursorOn

        // The character under the cursor, in the face colour, nudged the
        // way the text layer is.
        Ui.Label {
            x: -root.inkShift
            y: 0
            height: root.cellHeight
            text: root.cursorPos < root.text.length ? root.text.charAt(root.cursorPos) : ""
            color: root.face
            size: root.size
            font.letterSpacing: root.letterSpacing
            textFormat: Text.PlainText
        }
    }
}
