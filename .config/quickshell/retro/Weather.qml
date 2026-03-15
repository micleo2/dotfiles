pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string icon: weatherIcon
    readonly property string temp: weatherTemp

    property string weatherIcon: ""
    property string weatherTemp: ""

    Process {
        id: weatherProc
        command: ["curl", "-s", "wttr.in/?format=%c|%t"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|");
                root.weatherIcon = parts[0].replace(/\s+/g, '').trim();
                root.weatherTemp = (parts[1] || "").replace(/\s+/g, '').trim();
            }
        }
    }

    Timer {
        interval: 600000 // 10 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }
}
