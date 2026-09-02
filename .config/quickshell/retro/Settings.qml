pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Machine-local shell state.
//
// This lives under XDG_STATE_HOME rather than beside the QML because the retro
// config is one checkout shared between the desktop and the laptop: a chosen
// text size or monitor scale is a fact about a machine, not about the config.
// Quickshell.stateDir is deliberately not used — it keys on a hash of the config
// path, which is neither readable nor stable if the checkout moves.
Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/retro"

    property alias textSizePx: adapter.textSizePx
    property alias stayAwake: adapter.stayAwake
    property alias barTransparent: adapter.barTransparent
    property alias monitorScales: adapter.monitorScales
    property alias modules: adapter.modules
    property alias theme: adapter.theme
    property alias doNotDisturb: adapter.doNotDisturb
    property alias lockAfterSeconds: adapter.lockAfterSeconds

    // JsonAdapter only notices whole-property assignment, so the nested map has
    // to be replaced rather than mutated in place or the write never lands.
    function setMonitorScale(key, scale) {
        var next = {};
        for (var k in root.monitorScales)
            next[k] = root.monitorScales[k];
        next[key] = scale;
        root.monitorScales = next;
    }

    Process {
        // FileView will not create intermediate directories.
        running: true
        command: ["mkdir", "-p", root.stateDir]
        // Process.exited carries a QProcess::ExitStatus that Quickshell does
        // not expose to QML, so qmllint cannot type the handler.
        onExited: view.reload() // qmllint disable signal-handler-parameters
    }

    FileView {
        id: view

        path: root.stateDir + "/settings.json"
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: (error) => {
            // First run: materialise the defaults so the file is discoverable.
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter { // qmllint disable unresolved-type
            id: adapter

            property int textSizePx: 12
            // Key into Config.themes.
            property string theme: "default"
            property bool stayAwake: false
            property bool barTransparent: false
            // Notifications: silenced toasts go straight to history.
            property bool doNotDisturb: false
            // Lock screen: seconds of idle before locking, 0 to never.
            property int lockAfterSeconds: 600
            // monitor description -> scale
            property var monitorScales: ({})
            // module id -> "auto" | true | false (see Modules)
            property var modules: ({})
        }
    }
}
