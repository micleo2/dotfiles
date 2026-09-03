import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    readonly property string icon: weatherIcon
    readonly property string temp: weatherTemp
    property string weatherIcon: ""
    property string weatherTemp: ""
    property string _buf: ""

    function weatherCodeToEmoji(code) {
        if (code === 113)
            return "☀️";

        if (code === 116)
            return "⛅";

        if (code === 119 || code === 122)
            return "☁️";

        if (code >= 176 && code <= 299)
            return "🌧️";

        if (code >= 302 && code <= 321)
            return "🌧️";

        if (code >= 323 && code <= 395)
            return "🌨️";

        if (code === 143 || code === 248 || code === 260)
            return "🌫️";

        if (code >= 200 && code <= 232)
            return "⛈️";

        return "☁️";
    }

    Process {
        id: weatherProc

        command: ["curl", "-s", "wttr.in/?format=j1"]
        onRunningChanged: {
            if (running) {
                root._buf = "";
            } else {
                try {
                    const j = JSON.parse(root._buf);
                    const cc = j.current_condition[0];
                    root.weatherTemp = cc.temp_F + "°F";
                    const code = parseInt(cc.weatherCode, 10);
                    root.weatherIcon = root.weatherCodeToEmoji(code);
                } catch (e) {
                }
            }
        }

        stdout: SplitParser {
            onRead: (data) => {
                root._buf += data;
            }
        }

    }

    Timer {
        interval: root.weatherTemp === "" ? 30000 : 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

}
