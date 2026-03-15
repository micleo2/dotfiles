import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    property int percent: 0

    signal brightnessChanged()

    IpcHandler {
        function up() {
            root.percent = Math.min(100, root.percent + 10);
            setBrightness.command = ["ddcutil", "--bus", "3", "setvcp", "10", String(root.percent)];
            setBrightness.running = true;
            root.brightnessChanged();
        }

        function down() {
            root.percent = Math.max(0, root.percent - 10);
            setBrightness.command = ["ddcutil", "--bus", "3", "setvcp", "10", String(root.percent)];
            setBrightness.running = true;
            root.brightnessChanged();
        }

        target: "brightness"
    }

    Process {
        id: getBrightness

        command: ["ddcutil", "--bus", "3", "getvcp", "10", "-t"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 4)
                    root.percent = parseInt(parts[3], 10);

            }
        }

    }

    Process {
        id: setBrightness

        command: ["ddcutil", "--bus", "3", "setvcp", "10", "0"]
    }

}
