pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A row of fat LCD level bars: the first `filled` are lit, the rest ghosted.
Row {
    id: root

    property int segments: 10
    property int filled: 0
    // The row keeps this width however many segments it holds, so the panel
    // is the same size whether it shows 10 brightness steps or 20 volume ones.
    property int totalWidth: 216
    property int segmentHeight: 44
    property real ghost: 0.12

    readonly property int segmentWidth: Math.max(2, Math.floor((root.totalWidth - root.spacing * (root.segments - 1)) / root.segments))

    spacing: 4

    Repeater {
        model: root.segments

        Rectangle {
            required property int index

            width: root.segmentWidth
            height: root.segmentHeight
            color: Config.colors.text
            opacity: index < root.filled ? 1 : root.ghost
        }
    }
}
