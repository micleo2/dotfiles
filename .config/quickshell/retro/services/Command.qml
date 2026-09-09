import QtQuick
import Quickshell.Io

// One command whose whole output is the answer: run it, collect stdout,
// hand the text over in `collected`. A run asked for while one is in
// flight is not dropped but taken again the moment this one ends, so the
// result is never staler than the last request (and a command changed
// meanwhile runs in its new form).
//
// With `interval` set it also polls: every `interval` ms while `polling`,
// and once at once whenever polling turns on.
Process {
    id: root

    property int interval: 0
    property bool polling: false

    property bool again: false

    signal collected(string text)

    function run() {
        if (root.running) {
            root.again = true;
            return;
        }
        root.running = true;
    }

    stdout: StdioCollector {
        onStreamFinished: root.collected(text)
    }

    onRunningChanged: {
        if (!root.running && root.again) {
            root.again = false;
            root.running = true;
        }
    }

    // A property, not a child: Process has no default slot.
    readonly property Timer poll: Timer {
        running: root.polling && root.interval > 0
        interval: root.interval
        repeat: true
        triggeredOnStart: true
        onTriggered: root.run()
    }
}
