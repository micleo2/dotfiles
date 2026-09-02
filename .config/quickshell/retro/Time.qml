import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    // The clock itself, for anything that formats its own pieces.
    readonly property date now: clock.date

    readonly property string time: {
        Qt.formatDateTime(clock.date, " MMM d | hh:mma");
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

}
