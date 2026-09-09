pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../lcd" as Lcd
import "../lcd/text.js" as TextUtil
import "../ui" as Ui
import ".."

// The launcher module: header, query row, a page of result rows.
//
// Enter accepts, Shift+Enter hands back the typed text (dmenu only),
// Escape and Ctrl+C cancel. Up/Down, Ctrl+J/K, Ctrl+N/P and Tab walk the
// rows, PageUp/PageDown by a page, Alt+1..9,0 pick a visible row. Ctrl+U
// clears the query, the rest of the line editing is readline's
// (Ui.Readline). A click picks a row, the wheel moves the selection.
Item {
    id: root

    property bool inputEnabled: true

    readonly property int columns: 48
    readonly property int listRows: 10
    readonly property color ink: Config.colors.text
    // Selected-row text: the face colour was unreadable on the ink bar.
    readonly property color face: Config.colors.base

    readonly property bool apps: Launcher.mode === "apps"
    readonly property int iconCells: root.apps ? 2 : 0
    readonly property int textStart: root.apps ? 3 : 0

    property int sweep: 0
    // First visible match. Not `top`: that is a FINAL Item property.
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

    function follow() {
        var s = Launcher.selected;
        if (s < root.first)
            root.first = s;
        else if (s >= root.first + root.listRows)
            root.first = s - root.listRows + 1;
        var maxTop = Math.max(0, Launcher.matches.length - root.listRows);
        root.first = Math.max(0, Math.min(maxTop, root.first));
    }

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

    // The sweep waits a beat: a keystroke's fzf is back within a tick, and
    // a cell lit that briefly read as the label flashing. It runs in the
    // blank span between the label and the counter.
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

    implicitWidth: bezel.width + bezel.shadowOffset
    implicitHeight: bezel.height + bezel.shadowOffset

    Lcd.HiddenInput {
        id: input

        active: root.inputEnabled
        text: Launcher.query

        onTextChanged: {
            if (text !== Launcher.query)
                Launcher.query = text;
        }

        onAccepted: Launcher.accept()

        Keys.onPressed: (event) => {
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
            } else if (!Ui.Readline.handle(input, event)) {
                return;
            }
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: input.grab()
        onWheel: (wheel) => {
            Launcher.move(wheel.angleDelta.y > 0 ? -1 : 1);
        }
    }

    Lcd.Bezel {
        id: bezel

        Column {
            spacing: 6

            Lcd.CharGrid {
                id: headerGrid

                columns: root.columns
                rows: 1

                marks: Lcd.Cell {
                    grid: headerGrid
                    col: root.sweep
                    color: root.ink
                    visible: root.sweeping && root.inputEnabled
                }

                Lcd.CellText {
                    grid: headerGrid
                    text: root.label
                    color: root.ink
                }

                Lcd.CellText {
                    grid: headerGrid
                    align: Text.AlignRight
                    text: root.counter
                    color: root.ink
                }
            }

            Lcd.PromptRow {
                id: queryGrid

                columns: root.columns
                ink: root.ink
                text: Launcher.query
                cursorPosition: input.cursorPosition
                active: root.inputEnabled
            }

            Lcd.CharGrid {
                id: listGrid

                columns: root.columns
                rows: root.listRows

                // One solid bar, not lit cells: the gutters cut through the glyphs.
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
                        input.grab();
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

                        Lcd.CellText {
                            grid: listGrid
                            col: root.textStart
                            text: row.name
                            color: row.selectedRow ? root.face : root.ink
                        }

                        Lcd.CellText {
                            grid: listGrid
                            align: Text.AlignRight
                            text: row.detail
                            color: row.selectedRow ? root.face : root.ink
                            opacity: row.selectedRow ? 1 : 0.55
                            visible: row.detail !== ""
                        }
                    }
                }

                Lcd.CellText {
                    grid: listGrid
                    align: Text.AlignHCenter
                    visible: root.status !== ""
                    text: root.status
                    color: Config.colors.urgent
                }
            }
        }
    }
}
