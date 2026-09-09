pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A level-over-time plot as LCD columns: one per bucket, lit to the level
// and ghosted above it, so an empty column reads as a gap in the record
// rather than a reading of zero. Charging columns take the accent colour.
//
// The plot is its own range picker: a click (or Enter, or h/l under the
// cursor) steps the span, which saves the rows a list of ranges would take.
// The axis under it says which span is showing.
PopupControl {
    id: root

    // From BatteryHistory.series: { pct: 0-100 or null, charging: bool }.
    property var series: []
    property int chartHeight: 80
    property color drainColor: Config.colors.text
    property color chargeColor: Config.colors.accent
    property real ghost: Config.lcdGhost
    // Vertical rules, on the same divisions as the axis below.
    property int divisions: 4

    // +1 to the next span, -1 to the previous.
    signal stepped(int direction)

    readonly property int columns: root.series.length
    readonly property int columnWidth: root.columns > 0 ? Math.max(1, Math.floor(root.width / root.columns)) : 1

    implicitHeight: root.chartHeight

    function activate() {
        root.stepped(1);
    }

    function adjust(delta) {
        root.stepped(delta > 0 ? 1 : -1);
    }

    // The cursor is the same band PopupSlider wears, bled past the frame so
    // it shows as a ring around it.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        color: root.hasCursor ? Config.colors.highlight : "transparent"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        color: "transparent"
        border.width: 2
        border.color: Config.colors.outline
    }

    // Quarter rules and time rules, ghosted like the unlit segments.
    Repeater {
        model: 3

        Rectangle {
            required property int index

            x: 0
            y: Math.round(root.height * (index + 1) / 4)
            width: root.width
            height: 1
            color: root.drainColor
            opacity: root.ghost
        }
    }

    Repeater {
        model: Math.max(0, root.divisions - 1)

        Rectangle {
            required property int index

            x: Math.round(root.width * (index + 1) / root.divisions)
            y: 0
            width: 1
            height: root.height
            color: root.drainColor
            opacity: root.ghost
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        Repeater {
            model: root.columns

            Item {
                id: column

                required property int index
                readonly property var point: root.series[index]
                readonly property bool gap: !point || point.pct === null

                width: root.columnWidth
                height: root.height

                Rectangle {
                    anchors.fill: parent
                    color: root.drainColor
                    opacity: root.ghost
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: !column.gap
                    height: column.gap ? 0 : Math.max(1, Math.round(column.point.pct / 100 * root.height))
                    color: !column.gap && column.point.charging ? root.chargeColor : root.drainColor
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            mouse.accepted = true;
            root.stepped(mouse.button === Qt.RightButton ? -1 : 1);
        }
    }
}
