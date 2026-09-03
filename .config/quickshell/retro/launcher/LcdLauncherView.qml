pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../lcd" as Lcd
import "../lcd/text.js" as TextUtil
import "../ui" as Ui
import ".."

// The launcher as one Game & Watch LCD module in the OSD's frame: hard
// offset shadow, outlined bezel, dark face. Inside, a header row with the
// mode on the left and a pager count on the right, the query row with its
// block cursor, and a page of result rows. The selected row is a solid bar
// of ink with its text in the bezel colour. In apps mode each row leads with the app's icon, drained to
// the ink colour so it reads as a printed glyph rather than a picture.
//
// While fzf is running one lit cell sweeps the header, the lock's checking
// sweep. No match spells NO MATCH in the urgent ink.
//
// Enter accepts, Shift+Enter hands back the typed text (dmenu only),
// Escape and Ctrl+C cancel. Up/Down, Ctrl+J/K, Ctrl+N/P and Tab walk the
// rows, PageUp/PageDown by a page, Alt+1..9,0 pick a visible row. Ctrl+U
// clears the query. A click picks a row, the wheel moves the selection.
Item {
    id: root

    property bool inputEnabled: true

    readonly property real ghost: 0.12
    readonly property int pad: 18
    readonly property int columns: 48
    readonly property int listRows: 10
    readonly property color ink: Config.colors.text
    // Text on the selected row: the bezel colour, not the face, so it
    // stands off the lit bar the way the bezel stands off the face.
    readonly property color face: Config.colors.base

    readonly property bool apps: Launcher.mode === "apps"
    // Cells the icon column takes, and where a row's text begins.
    readonly property int iconCells: root.apps ? 2 : 0
    readonly property int textStart: root.apps ? 3 : 0

    property bool cursorOn: true
    property int sweep: 0
    // First visible match.
    property int first: 0

    readonly property string label: TextUtil.fit(String(Launcher.prompt !== "" ? Launcher.prompt : (root.apps ? "APPS" : "MENU")).toUpperCase(), 20)
    readonly property int count: Launcher.matches.length
    readonly property string counter: root.pad3(root.count > 0 ? Launcher.selected + 1 : 0) + "/" + root.pad3(root.count)
    readonly property string status: Launcher.items.length === 0 ? "EMPTY" : (root.count === 0 ? "NO MATCH" : "")

    readonly property var visibleRows: {
        var out = [];
        var end = Math.min(Launcher.matches.length, root.first + root.listRows);
        for (var i = root.first; i < end; i++) {
            var item = Launcher.items[Launcher.matches[i]];
            if (item !== undefined)
                out.push(item);
        }
        return out;
    }

    function pad3(n) {
        var s = String(Math.min(999, n));
        while (s.length < 3)
            s = "0" + s;
        return s;
    }

    // A row's text: the name, and the detail right-aligned and dimmed when
    // there is room for both.
    function rowText(item) {
        var avail = root.columns - root.textStart;
        return TextUtil.fit(String(item.text), avail);
    }

    function rowDetail(item) {
        var name = root.rowText(item);
        var detail = String(item.detail || "");
        if (detail === "")
            return "";
        var room = root.columns - root.textStart - name.length - 2;
        if (room < 4)
            return "";
        return TextUtil.fit(detail, room);
    }

    function focusInput() {
        if (root.inputEnabled)
            input.forceActiveFocus();
    }

    function powerOn() {
        headerGrid.flash = true;
        queryGrid.flash = true;
        listGrid.flash = true;
    }

    function blink() {
        root.cursorOn = true;
        blinkTimer.restart();
    }

    // Keeps the selection on the page.
    function follow() {
        var s = Launcher.selected;
        if (s < root.first)
            root.first = s;
        else if (s >= root.first + root.listRows)
            root.first = s - root.listRows + 1;
        var maxTop = Math.max(0, Launcher.matches.length - root.listRows);
        root.first = Math.max(0, Math.min(maxTop, root.first));
    }

    onInputEnabledChanged: {
        if (root.inputEnabled) {
            root.powerOn();
            Qt.callLater(root.focusInput);
        }
    }

    Component.onCompleted: Qt.callLater(root.focusInput)

    Connections {
        target: Launcher

        function onQueryChanged() {
            if (input.text !== Launcher.query)
                input.text = Launcher.query;
        }

        function onSelectedChanged() {
            root.follow();
        }

        function onMatchesChanged() {
            root.first = 0;
            root.follow();
        }

        function onOpened() {
            root.first = 0;
            input.cursorPosition = 0;
        }
    }

    Timer {
        id: blinkTimer

        running: root.inputEnabled
        interval: 530
        repeat: true
        onTriggered: root.cursorOn = !root.cursorOn
    }

    // The sweep only starts once a match has been running for a beat: a
    // keystroke's fzf is back within a tick, and a cell lit for that long
    // reads as the label flashing. It runs in the empty span between the
    // label and the counter, so nothing it crosses is text.
    readonly property int sweepFrom: root.label.length + 1
    readonly property int sweepTo: root.columns - root.counter.length - 1
    property bool sweeping: false

    Timer {
        id: sweepDelay

        running: Launcher.busy && root.inputEnabled
        interval: 150
        onTriggered: root.sweeping = true
    }

    onSweepingChanged: {
        if (root.sweeping)
            root.sweep = root.sweepFrom;
    }

    Connections {
        target: Launcher

        function onBusyChanged() {
            if (!Launcher.busy)
                root.sweeping = false;
        }
    }

    Timer {
        running: root.sweeping && root.inputEnabled
        interval: 60
        repeat: true
        onTriggered: {
            var next = root.sweep + 1;
            root.sweep = next >= root.sweepTo ? root.sweepFrom : next;
        }
    }

    implicitWidth: bezel.width + 4
    implicitHeight: bezel.height + 4

    // Keys land here. Nothing of it is drawn; the grids below are the echo.
    TextInput {
        id: input

        width: 1
        height: 1
        opacity: 0
        enabled: root.inputEnabled
        text: Launcher.query
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

        onTextChanged: {
            if (text !== Launcher.query)
                Launcher.query = text;
        }

        onCursorPositionChanged: root.blink()

        onAccepted: Launcher.accept()

        Keys.onPressed: (event) => {
            root.blink();
            var ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
            var shift = (event.modifiers & Qt.ShiftModifier) !== 0;
            var alt = (event.modifiers & Qt.AltModifier) !== 0;
            if (event.key === Qt.Key_Escape || (ctrl && event.key === Qt.Key_C)) {
                Launcher.dismiss();
            } else if (shift && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                Launcher.acceptCustom();
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                Launcher.move(1);
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                Launcher.move(-1);
            } else if (event.key === Qt.Key_PageDown) {
                Launcher.move(root.listRows);
            } else if (event.key === Qt.Key_PageUp) {
                Launcher.move(-root.listRows);
            } else if (ctrl && event.key === Qt.Key_U) {
                Launcher.query = "";
            } else if (alt && event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                var row = event.key === Qt.Key_0 ? 9 : event.key - Qt.Key_1;
                if (row < root.visibleRows.length) {
                    Launcher.select(root.first + row);
                    Launcher.accept();
                }
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
            Launcher.move(wheel.angleDelta.y > 0 ? -1 : 1);
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

            // Row: the mode, the pager count, and the sweep while matching.
            Lcd.CharGrid {
                id: headerGrid

                columns: root.columns
                rows: 1
                ghost: root.ghost

                marks: Rectangle {
                    x: root.sweep * headerGrid.cellWidth
                    y: 0
                    width: headerGrid.cellWidth - 1
                    height: headerGrid.cellHeight - 1
                    color: root.ink
                    visible: root.sweeping && root.inputEnabled
                }

                Ui.Label {
                    x: 0
                    y: headerGrid.rowY(0)
                    height: headerGrid.cellHeight
                    text: root.label
                    color: root.ink
                    size: headerGrid.size
                    font.letterSpacing: headerGrid.letterSpacing
                    textFormat: Text.PlainText
                }

                Ui.Label {
                    x: (headerGrid.columns - root.counter.length) * headerGrid.cellWidth
                    y: headerGrid.rowY(0)
                    height: headerGrid.cellHeight
                    text: root.counter
                    color: root.ink
                    size: headerGrid.size
                    font.letterSpacing: headerGrid.letterSpacing
                    textFormat: Text.PlainText
                }
            }

            // Row: the query, with the cursor as a lit cell.
            Lcd.PromptRow {
                id: queryGrid

                columns: root.columns
                ghost: root.ghost
                ink: root.ink
                text: Launcher.query
                cursorPosition: input.cursorPosition
                cursorOn: root.inputEnabled && root.cursorOn
            }

            // The page of results.
            Lcd.CharGrid {
                id: listGrid

                columns: root.columns
                rows: root.listRows
                ghost: root.ghost

                // The selected row: one solid bar of ink across the row.
                // Not a run of cells: the gutters would cut through every
                // glyph drawn over it.
                marks: Item {
                    anchors.fill: parent

                    Rectangle {
                        readonly property int row: Launcher.selected - root.first

                        x: 0
                        y: listGrid.rowY(row)
                        width: listGrid.columns * listGrid.cellWidth - 1
                        height: listGrid.cellHeight - 1
                        color: root.ink
                        visible: root.count > 0 && row >= 0 && row < root.listRows
                    }

                    // Icons sit on the cell layer: they are ink on the
                    // face, not text.
                    Repeater {
                        model: root.apps ? root.visibleRows : []

                        Item {
                            id: iconCell

                            required property var modelData
                            required property int index

                            readonly property bool selectedRow: root.first + index === Launcher.selected
                            readonly property string source: modelData.icon !== "" ? Quickshell.iconPath(modelData.icon, true) : ""

                            x: 0
                            y: listGrid.rowY(index)
                            width: root.iconCells * listGrid.cellWidth - 1
                            height: listGrid.cellHeight - 1
                            visible: iconCell.source !== ""

                            IconImage {
                                id: icon

                                anchors.centerIn: parent
                                width: parent.height
                                height: parent.height
                                source: iconCell.source
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: icon
                                source: icon
                                saturation: -1
                                colorization: 1
                                colorizationColor: iconCell.selectedRow ? root.face : root.ink
                                blurEnabled: false
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        var row = Math.floor(mouse.y / listGrid.cellHeight);
                        if (row >= 0 && row < root.visibleRows.length) {
                            Launcher.select(root.first + row);
                            Launcher.accept();
                        }
                        root.focusInput();
                    }
                    onWheel: (wheel) => {
                        Launcher.move(wheel.angleDelta.y > 0 ? -1 : 1);
                    }
                }

                Repeater {
                    model: root.visibleRows

                    Item {
                        id: row

                        required property var modelData
                        required property int index

                        readonly property bool selectedRow: root.first + index === Launcher.selected
                        readonly property string name: root.rowText(modelData)
                        readonly property string detail: root.rowDetail(modelData)

                        x: 0
                        y: listGrid.rowY(index)
                        width: listGrid.width
                        height: listGrid.cellHeight

                        Ui.Label {
                            x: root.textStart * listGrid.cellWidth
                            y: 0
                            height: listGrid.cellHeight
                            text: row.name
                            color: row.selectedRow ? root.face : root.ink
                            size: listGrid.size
                            font.letterSpacing: listGrid.letterSpacing
                            textFormat: Text.PlainText
                        }

                        Ui.Label {
                            x: (listGrid.columns - row.detail.length) * listGrid.cellWidth
                            y: 0
                            height: listGrid.cellHeight
                            text: row.detail
                            color: row.selectedRow ? root.face : root.ink
                            opacity: row.selectedRow ? 1 : 0.55
                            size: listGrid.size
                            font.letterSpacing: listGrid.letterSpacing
                            textFormat: Text.PlainText
                            visible: row.detail !== ""
                        }
                    }
                }

                Ui.Label {
                    visible: root.status !== ""
                    x: Math.floor((listGrid.columns - root.status.length) / 2) * listGrid.cellWidth
                    y: listGrid.rowY(0)
                    height: listGrid.cellHeight
                    text: root.status
                    color: Config.colors.urgent
                    size: listGrid.size
                    font.letterSpacing: listGrid.letterSpacing
                    textFormat: Text.PlainText
                }
            }
        }
    }
}
