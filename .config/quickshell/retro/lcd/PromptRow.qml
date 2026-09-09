pragma ComponentBehavior: Bound

import QtQuick
import "../ui" as Ui
import ".."

// A prompt, a line being typed and a block cursor. Takes no keys; the
// owner's TextInput does, and its text and cursorPosition are mirrored in.
// The cursor blinks while `active`, and any edit lights it again so it is
// never mid-blink when the line moves.
CharGrid {
    id: root

    property string prompt: "> "
    property string text: ""
    property int cursorPosition: 0
    property color ink: Config.colors.text
    property color face: Config.colors.shadow
    property bool active: true

    property bool cursorOn: true

    readonly property int avail: Math.max(1, root.columns - root.prompt.length)
    readonly property int cursorPos: Math.max(0, Math.min(root.cursorPosition, root.text.length))
    readonly property int start: root.cursorPos >= root.avail ? root.cursorPos - root.avail + 1 : 0
    readonly property string shown: root.text.substr(root.start, root.avail)
    readonly property int cursorCell: root.prompt.length + root.cursorPos - root.start

    rows: 1

    function blink() {
        root.cursorOn = true;
        blinkTimer.restart();
    }

    onTextChanged: root.blink()
    onCursorPositionChanged: root.blink()

    Timer {
        id: blinkTimer

        running: root.active
        interval: 530
        repeat: true
        onTriggered: root.cursorOn = !root.cursorOn
    }

    CellText {
        grid: root
        text: root.prompt + root.shown
        color: root.ink
    }

    marks: Cell {
        grid: root
        col: root.cursorCell
        color: root.ink
        visible: root.active && root.cursorOn

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
