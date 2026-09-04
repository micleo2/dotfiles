pragma ComponentBehavior: Bound

import QtQuick
import "../lcd" as Lcd
import "../lcd/text.js" as TextUtil
import "../ui" as Ui
import ".."

// The submap cheat sheet as a Game & Watch LCD module in the OSD's frame:
// hard offset shadow, outlined bezel, dark face. Inside, a header row with
// the submap's name and one character grid of entries, sorted and flowing
// down each column then on to the next, like `ls`. The trigger key is drawn
// in the urgent colour, the rest of the label in the text colour: the colour
// change is the highlight, so a chord like SUPER+A needs no bar.
Item {
    id: root

    property var entries: []
    property string submapName: ""

    // Entries per column. Fewer means a wider, shorter module.
    property int perColumn: 4
    // Blank cells between columns.
    property int gap: 2

    readonly property real ghost: 0.12
    readonly property int pad: 18
    readonly property color ink: Config.colors.text
    // The trigger key, the palette's alert colour.
    readonly property color key: Config.colors.urgent

    readonly property var sortedEntries: root.entries.slice().sort((a, b) => String(a.label).localeCompare(String(b.label)))

    // Where the key sits inside the label: a single-character key is
    // matched case-sensitively anywhere (k -> ma[k]era), a longer key only
    // as a case-insensitive prefix ([sh]utdown). Anything else is spelled
    // out ahead of the label ([SUPER+A] apps).
    function splitLabel(key, label) {
        if (key.length === 1) {
            const at = label.indexOf(key);
            if (at >= 0)
                return {
                    pre: label.substring(0, at),
                    key: key,
                    post: label.substring(at + 1)
                };
        } else if (label.toLowerCase().startsWith(key.toLowerCase())) {
            return {
                pre: "",
                key: label.substring(0, key.length),
                post: label.substring(key.length)
            };
        }
        return {
            pre: "",
            key: key,
            post: " " + label
        };
    }

    // Every entry placed on the grid in cells: its row, the column's start
    // cell, and the three pieces of its text. Columns are as wide as their
    // longest entry, so a column of short labels does not pay for a long
    // one elsewhere.
    readonly property var layout: {
        const cells = [];
        let x = 0;
        for (let i = 0; i < root.sortedEntries.length; i += root.perColumn) {
            const group = root.sortedEntries.slice(i, i + root.perColumn);
            let width = 0;
            for (let r = 0; r < group.length; r++) {
                const part = root.splitLabel(String(group[r].key), String(group[r].label));
                cells.push({
                    row: r,
                    x: x,
                    pre: part.pre,
                    key: part.key,
                    post: part.post
                });
                width = Math.max(width, part.pre.length + part.key.length + part.post.length);
            }
            x += width + root.gap;
        }
        return {
            columns: Math.max(1, x - root.gap),
            cells: cells
        };
    }

    readonly property int columns: root.layout.columns
    readonly property int rows: Math.max(1, Math.min(root.perColumn, root.sortedEntries.length))
    readonly property string label: TextUtil.fit(root.submapName.toUpperCase(), root.columns)

    implicitWidth: bezel.width + 4
    implicitHeight: bezel.height + 4

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

            // Row: which submap this is.
            Lcd.CharGrid {
                id: headerGrid

                columns: root.columns
                rows: 1
                ghost: root.ghost

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
            }

            // The entries.
            Lcd.CharGrid {
                id: keyGrid

                columns: root.columns
                rows: root.rows
                ghost: root.ghost

                Repeater {
                    model: root.layout.cells

                    Item {
                        id: entry

                        required property var modelData

                        readonly property int start: modelData.x

                        x: 0
                        y: keyGrid.rowY(modelData.row)
                        width: keyGrid.width
                        height: keyGrid.cellHeight

                        Ui.Label {
                            x: entry.start * keyGrid.cellWidth
                            height: keyGrid.cellHeight
                            text: entry.modelData.pre
                            color: root.ink
                            size: keyGrid.size
                            font.letterSpacing: keyGrid.letterSpacing
                            textFormat: Text.PlainText
                        }

                        Ui.Label {
                            x: (entry.start + entry.modelData.pre.length) * keyGrid.cellWidth
                            height: keyGrid.cellHeight
                            text: entry.modelData.key
                            color: root.key
                            size: keyGrid.size
                            font.letterSpacing: keyGrid.letterSpacing
                            textFormat: Text.PlainText
                        }

                        Ui.Label {
                            x: (entry.start + entry.modelData.pre.length + entry.modelData.key.length) * keyGrid.cellWidth
                            height: keyGrid.cellHeight
                            text: entry.modelData.post
                            color: root.ink
                            size: keyGrid.size
                            font.letterSpacing: keyGrid.letterSpacing
                            textFormat: Text.PlainText
                        }
                    }
                }
            }
        }
    }
}
