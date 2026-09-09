pragma ComponentBehavior: Bound

import QtQuick
import ".."

// The time axis under a history plot: a tick at every division, a label on
// every few of them, "now" at the right edge. The labels count back from
// now without a sign; nothing here can be ahead of it. Labels every division would
// overlap at this width, so the tick spacing and the label spacing are set
// separately per span, and the plots draw their vertical rules on the same
// divisions.
Item {
    id: root

    // Seconds, matching the plot above.
    property int span: 86400

    readonly property int minorStep: root.span <= 21600 ? 1800 : (root.span <= 86400 ? 7200 : 43200)
    readonly property int labelStep: root.span <= 21600 ? 3600 : (root.span <= 86400 ? 14400 : 86400)
    readonly property int divisions: Math.max(1, Math.round(root.span / root.minorStep))
    readonly property int labelEvery: Math.max(1, Math.round(root.labelStep / root.minorStep))

    readonly property int fontSize: Math.round(Config.settings.bar.fontSize * 0.75)
    readonly property int tickHeight: 6

    implicitWidth: parent ? parent.width : 0
    implicitHeight: root.tickHeight + 2 + root.fontSize

    // One unit per axis: hours up to a day, so 24h reads as the day it is,
    // and days once the span is longer, so the last day is "-1d" not "-24h".
    function label(seconds) {
        if (root.span > 86400) {
            var days = seconds / 86400;
            return (Number.isInteger(days) ? days : days.toFixed(1)) + "d";
        }
        var hours = seconds / 3600;
        return (Number.isInteger(hours) ? hours : hours.toFixed(1)) + "h";
    }

    function tickX(i) {
        return Math.min(root.width - 1, Math.round(i * root.width / root.divisions));
    }

    Repeater {
        model: root.divisions + 1

        Rectangle {
            required property int index
            readonly property bool labelled: index % root.labelEvery === 0

            x: root.tickX(index)
            y: 0
            width: 1
            height: labelled ? root.tickHeight : Math.round(root.tickHeight / 2)
            color: Config.colors.outline
            opacity: labelled ? 0.7 : 0.4
        }
    }

    Repeater {
        model: root.divisions + 1

        Label {
            id: tickLabel

            required property int index
            readonly property int centre: root.tickX(index)

            visible: index % root.labelEvery === 0
            // Centred on the tick, but kept inside the axis at either end.
            x: Math.max(0, Math.min(root.width - tickLabel.implicitWidth, tickLabel.centre - Math.round(tickLabel.implicitWidth / 2)))
            y: root.tickHeight + 2
            size: root.fontSize
            opacity: 0.7
            text: index === root.divisions ? "now" : root.label(root.span - index * root.minorStep)
        }
    }
}
