import QtQuick
import Quickshell.Io

// A process kept alive while `wanted`: started when wanted, brought back
// `delay` ms after it exits, stopped when no longer wanted. `running` is
// derived here and nowhere else, so no handler ever overwrites the binding
// with a plain value (which would leave the process deaf to `wanted`).
//
// One that keeps dying the moment it starts (no socket to open, a bad
// argument, a missing module) would otherwise respawn in silence forever,
// so after `maxShortExits` exits in a row within `shortExit` ms of starting
// it is given up on and `failed` set. A binary that cannot be spawned at all
// counts the same way, with Quickshell's own warning to say so. Turning
// `wanted` off and on again tries afresh.
Process {
    id: root

    property bool wanted: false
    property int delay: 3000
    property int shortExit: 5000
    property int maxShortExits: 5

    readonly property bool failed: root.shortExits >= root.maxShortExits
    property int shortExits: 0
    property bool waiting: false
    property double startedAt: 0
    property bool sawExit: false

    running: root.wanted && !root.failed && !root.waiting

    onStarted: {
        root.startedAt = Date.now();
        root.sawExit = false;
    }

    // Process.exited carries a QProcess::ExitStatus that Quickshell does
    // not expose to QML, so qmllint cannot type the handler.
    onExited: { // qmllint disable signal-handler-parameters
        root.sawExit = true;
        root.count(Date.now() - root.startedAt < root.shortExit);
    }

    // A spawn failure reports only through `running` falling; `exited`
    // never comes. It is as short an exit as there is.
    onRunningChanged: {
        if (root.running)
            return;
        if (!root.sawExit)
            root.count(true);
        root.sawExit = false;
    }

    onWantedChanged: {
        if (root.wanted)
            return;
        root.shortExits = 0;
        root.waiting = false;
        restart.stop();
    }

    function count(short) {
        root.shortExits = short ? root.shortExits + 1 : 0;
        if (root.failed) {
            console.warn("daemon: giving up on " + root.command.join(" ") + " after " + root.shortExits + " immediate exits");
            return;
        }
        if (root.wanted) {
            root.waiting = true;
            restart.restart();
        }
    }

    // A property, not a child: Process has no default slot.
    readonly property Timer restart: Timer {
        interval: root.delay
        onTriggered: root.waiting = false
    }
}
