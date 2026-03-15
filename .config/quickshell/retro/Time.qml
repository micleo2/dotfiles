import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    readonly property string time: {
        Qt.formatDateTime(clock.date, " MMM d | hh:mma");
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

}
