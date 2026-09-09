pragma ComponentBehavior: Bound

import QtQuick
import "../lcd" as Lcd
import "../lcd/text.js" as TextUtil
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

    implicitWidth: bezel.width + bezel.shadowOffset
    implicitHeight: bezel.height + bezel.shadowOffset

    Lcd.Bezel {
        id: bezel

        Column {
            spacing: 6

            // Row: which submap this is.
            Lcd.CharGrid {
                id: headerGrid

                columns: root.columns
                rows: 1

                Lcd.CellText {
                    grid: headerGrid
                    text: root.label
                    color: root.ink
                }
            }

            // The entries.
            Lcd.CharGrid {
                id: keyGrid

                columns: root.columns
                rows: root.rows

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

                        Lcd.CellText {
                            grid: keyGrid
                            col: entry.start
                            text: entry.modelData.pre
                            color: root.ink
                        }

                        Lcd.CellText {
                            grid: keyGrid
                            col: entry.start + entry.modelData.pre.length
                            text: entry.modelData.key
                            color: root.key
                        }

                        Lcd.CellText {
                            grid: keyGrid
                            col: entry.start + entry.modelData.pre.length + entry.modelData.key.length
                            text: entry.modelData.post
                            color: root.ink
                        }
                    }
                }
            }
        }
    }
}
