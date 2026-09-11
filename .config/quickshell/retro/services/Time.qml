import QtQuick
import Quickshell
import "../lock"
pragma Singleton

// The one clock. It ticks for the bar's clock chip and for the lock screen,
// and stops when neither is showing.
Singleton {
    id: root

    // The clock itself, for anything that formats its own pieces.
    readonly property date now: clock.date

    readonly property string time: {
        Qt.formatDateTime(clock.date, " MMM d | hh:mma");
    }

    SystemClock {
        id: clock

        enabled: Modules.on("clock") || Lock.inputActive
        precision: SystemClock.Seconds
    }

}
