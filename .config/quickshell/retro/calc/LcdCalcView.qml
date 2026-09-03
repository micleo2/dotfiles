pragma ComponentBehavior: Bound

import QtQuick
import "../lcd" as Lcd
import "../lcd/text.js" as TextUtil
import "../ui" as Ui
import ".."

// The calculator as one Game & Watch LCD module in the OSD's frame: hard
// offset shadow, outlined bezel, dark face. Inside, a row of controls, a
// character-grid console that scrolls like the terminal qalc runs in
// (`> line`, then `= result` under it, errors in the urgent ink), the line
// being typed with a blinking block cursor, and two dimmed rows where
// `= result` for the draft appears as it is typed. A draft is never shown
// as an error: most of them are, until they are finished.
//
// Enter commits the line; Ctrl+V commits it, copies its result and closes;
// Escape closes. Ctrl+C clears the line, Ctrl+L the console. Up and Down
// walk the committed lines, PageUp and PageDown scroll the console.
Item {
    id: root

    property bool inputEnabled: true

    readonly property real ghost: 0.12
    readonly property int pad: 18
    readonly property int columns: 44
    readonly property int consoleRows: 12
    readonly property int previewRows: 2
    readonly property color ink: Config.colors.text

    // Rows from the bottom of the console.
    property int scroll: 0
    property bool cursorOn: true
    // Where Up/Down stand in the history; -1 is the line being written.
    property int historyAt: -1
    property string stash: ""

    readonly property string hint: "^C CLR LINE  ^L CLR ALL  ^V COPY  ESC CLOSE"

    // Every console row, oldest first: {text, alarm}.
    readonly property var consoleLines: {
        var out = [];
        var entries = Calculator.entries;
        for (var i = 0; i < entries.length; i++) {
            root.pushRows(out, "> " + entries[i].input);
            var shown = Calculator.display(entries[i].lines, true);
            for (var j = 0; j < shown.length; j++)
                root.pushRows(out, shown[j]);
        }
        return out;
    }
    readonly property int maxScroll: Math.max(0, root.consoleLines.length - root.consoleRows)
    readonly property var visibleLines: {
        var end = root.consoleLines.length - Math.min(root.scroll, root.maxScroll);
        return root.consoleLines.slice(Math.max(0, end - root.consoleRows), end);
    }

    readonly property var previewLines: {
        var out = [];
        var shown = Calculator.display(Calculator.preview, false);
        for (var i = 0; i < shown.length; i++)
            root.pushRows(out, shown[i]);
        return out.slice(-root.previewRows);
    }

    // The draft, windowed so the cursor is always on the grid.
    readonly property string draft: Calculator.draft
    readonly property int avail: root.columns - 2
    readonly property int cursorPos: Math.min(input.cursorPosition, root.draft.length)
    readonly property int start: root.cursorPos >= root.avail ? root.cursorPos - root.avail + 1 : 0
    readonly property string shownDraft: root.draft.substr(root.start, root.avail)
    readonly property int cursorCell: 2 + root.cursorPos - root.start

    function pushRows(out, text) {
        var alarm = /^(error|warning):/i.test(text);
        var rows = TextUtil.wrap(text, root.columns, 1000000);
        if (rows.length === 0)
            rows = [""];
        for (var i = 0; i < rows.length; i++)
            out.push({
                text: rows[i],
                alarm: alarm
            });
    }

    function focusInput() {
        if (root.inputEnabled)
            input.forceActiveFocus();
    }

    function powerOn() {
        headerGrid.flash = true;
        consoleGrid.flash = true;
        inputGrid.flash = true;
        previewGrid.flash = true;
    }

    function blink() {
        root.cursorOn = true;
        blinkTimer.restart();
    }

    function recall(delta) {
        var lines = Calculator.history;
        if (lines.length === 0)
            return;
        if (root.historyAt < 0) {
            if (delta > 0)
                return;
            root.stash = Calculator.draft;
            root.historyAt = lines.length - 1;
        } else {
            var next = root.historyAt + delta;
            if (next >= lines.length) {
                root.historyAt = -1;
                Calculator.draft = root.stash;
                input.cursorPosition = input.text.length;
                return;
            }
            root.historyAt = Math.max(0, next);
        }
        Calculator.draft = lines[root.historyAt];
        input.cursorPosition = input.text.length;
    }

    onInputEnabledChanged: {
        if (root.inputEnabled) {
            root.scroll = 0;
            root.powerOn();
            Qt.callLater(root.focusInput);
        }
    }

    Component.onCompleted: Qt.callLater(root.focusInput)

    Connections {
        target: Calculator

        function onDraftChanged() {
            if (input.text !== Calculator.draft)
                input.text = Calculator.draft;
        }

        function onCommitted() {
            root.scroll = 0;
            root.historyAt = -1;
        }

        function onCleared() {
            root.scroll = 0;
        }
    }

    Timer {
        id: blinkTimer

        running: root.inputEnabled
        interval: 530
        repeat: true
        onTriggered: root.cursorOn = !root.cursorOn
    }

    implicitWidth: bezel.width + 4
    implicitHeight: bezel.height + 4

    // Keys land here. Nothing of it is drawn; the grid below is the echo.
    TextInput {
        id: input

        width: 1
        height: 1
        opacity: 0
        enabled: root.inputEnabled
        text: Calculator.draft
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

        onTextChanged: {
            if (text !== Calculator.draft)
                Calculator.draft = text;
        }

        onCursorPositionChanged: root.blink()

        onAccepted: Calculator.commit(false)

        Keys.onPressed: (event) => {
            root.blink();
            var ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
            if (event.key === Qt.Key_Escape) {
                Calculator.dismiss();
            } else if (ctrl && event.key === Qt.Key_V) {
                Calculator.commit(true);
            } else if (ctrl && event.key === Qt.Key_C) {
                Calculator.draft = "";
            } else if (ctrl && event.key === Qt.Key_L) {
                Calculator.clear();
            } else if (event.key === Qt.Key_Up) {
                root.recall(-1);
            } else if (event.key === Qt.Key_Down) {
                root.recall(1);
            } else if (event.key === Qt.Key_PageUp) {
                root.scroll = Math.min(root.maxScroll, root.scroll + Math.floor(root.consoleRows / 2));
            } else if (event.key === Qt.Key_PageDown) {
                root.scroll = Math.max(0, root.scroll - Math.floor(root.consoleRows / 2));
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
            var step = wheel.angleDelta.y > 0 ? 1 : -1;
            root.scroll = Math.max(0, Math.min(root.maxScroll, root.scroll + step));
        }
    }

    // The frame language: hard offset shadow, outlined bezel, dark face.
    Rectangle {
        x: bezel.x + 4
        y: bezel.y + 4
        width: bezel.width
        height: bezel.height
        color: Config.colors.outline
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
            spacing: 6

            // Row: the controls.
            Lcd.CharGrid {
                id: headerGrid

                columns: root.columns
                rows: 1
                ghost: root.ghost

                Ui.Label {
                    x: (headerGrid.columns - root.hint.length) * headerGrid.cellWidth
                    y: headerGrid.rowY(0)
                    height: headerGrid.cellHeight
                    text: root.hint
                    color: root.ink
                    size: headerGrid.size
                    font.letterSpacing: headerGrid.letterSpacing
                    textFormat: Text.PlainText
                }
            }

            // The console: the last rows of the session, bottom-anchored.
            Lcd.CharGrid {
                id: consoleGrid

                columns: root.columns
                rows: root.consoleRows
                ghost: root.ghost

                Repeater {
                    model: root.visibleLines

                    Ui.Label {
                        required property var modelData
                        required property int index

                        x: 0
                        y: consoleGrid.rowY(root.consoleRows - root.visibleLines.length + index)
                        height: consoleGrid.cellHeight
                        text: modelData.text
                        color: modelData.alarm ? Config.colors.urgent : root.ink
                        size: consoleGrid.size
                        font.letterSpacing: consoleGrid.letterSpacing
                        textFormat: Text.PlainText
                    }
                }
            }

            // Row: the prompt and the draft, with the cursor as a lit cell.
            Lcd.CharGrid {
                id: inputGrid

                columns: root.columns
                rows: 1
                ghost: root.ghost

                Ui.Label {
                    x: 0
                    y: inputGrid.rowY(0)
                    height: inputGrid.cellHeight
                    text: "> " + root.shownDraft
                    color: root.ink
                    size: inputGrid.size
                    font.letterSpacing: inputGrid.letterSpacing
                    textFormat: Text.PlainText
                }

                // The cursor is a lit cell, so it sits on the cell layer.
                marks: Rectangle {
                    x: root.cursorCell * inputGrid.cellWidth
                    y: 0
                    width: inputGrid.cellWidth - 1
                    height: inputGrid.cellHeight - 1
                    color: root.ink
                    visible: root.inputEnabled && root.cursorOn

                    // The character under the cursor, in the face colour,
                    // nudged the way the text layer is.
                    Ui.Label {
                        x: -inputGrid.inkShift
                        y: 0
                        height: inputGrid.cellHeight
                        text: root.cursorPos < root.draft.length ? root.draft.charAt(root.cursorPos) : ""
                        color: Config.colors.shadow
                        size: inputGrid.size
                        font.letterSpacing: inputGrid.letterSpacing
                        textFormat: Text.PlainText
                    }
                }
            }

            // Rows: qalc's answer to the draft, dimmed until it is committed.
            Lcd.CharGrid {
                id: previewGrid

                columns: root.columns
                rows: root.previewRows
                ghost: root.ghost

                Repeater {
                    model: root.previewLines

                    Ui.Label {
                        required property var modelData
                        required property int index

                        x: 0
                        y: previewGrid.rowY(root.previewRows - root.previewLines.length + index)
                        height: previewGrid.cellHeight
                        text: modelData.text
                        color: modelData.alarm ? Config.colors.urgent : root.ink
                        opacity: 0.55
                        size: previewGrid.size
                        font.letterSpacing: previewGrid.letterSpacing
                        textFormat: Text.PlainText
                    }
                }
            }
        }
    }
}
