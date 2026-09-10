pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A stepped slider drawn as discrete blocks, in the register of the segmented
// bucket in osd/LcdOsd.qml rather than as a smooth track.
PopupControl {
    id: root

    // Discrete stops. Values may be any numbers; the slider snaps between them.
    property var stops: []
    property int index: 0

    signal moved(int index)

    implicitHeight: 26

    // Evenly spaced percentages, `step` apart, ending at 100: the stops a
    // level control (volume, a backlight) snaps between. Pair with
    // percentIndex() for the stop a level is on.
    function percentStops(step) {
        var out = [];
        for (var v = step; v <= 100; v += step)
            out.push(v);
        return out;
    }

    function percentIndex(percent, step) {
        return Math.round(percent / step) - 1;
    }

    function indexAt(px) {
        if (root.stops.length === 0)
            return 0;
        var slot = Math.floor(px / (root.width / root.stops.length));
        return Math.max(0, Math.min(root.stops.length - 1, slot));
    }

    function adjust(delta) {
        if (root.stops.length === 0)
            return;
        root.moved(Math.max(0, Math.min(root.stops.length - 1, root.index + delta)));
    }

    // The cursor is the same filled block PopupRow and PopupToggle paint, bled
    // a few pixels past the track so it reads as a band behind the blocks.
    // `highlight` is only a shade off `base` on every palette, so a 2px frame
    // in it is invisible; only a solid fill carries enough area to register.
    // The lit blocks keep their text fill and the unlit ones show the band
    // through, so the level stays readable on top of it.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        color: root.hasCursor ? Config.colors.highlight : "transparent"
    }

    Row {
        anchors.fill: parent
        spacing: 3

        Repeater {
            model: root.stops.length

            Rectangle {
                required property int index

                width: (root.width - (root.stops.length - 1) * 3) / Math.max(1, root.stops.length)
                height: root.height
                color: index <= root.index ? Config.colors.text : "transparent"
                border.width: 2
                border.color: Config.colors.outline
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => {
            mouse.accepted = true;
            root.moved(root.indexAt(mouse.x));
        }
        onPositionChanged: (mouse) => {
            if (pressed)
                root.moved(root.indexAt(mouse.x));
        }
    }
}
