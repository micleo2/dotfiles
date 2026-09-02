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

    // JsonAdapter only notices whole-property assignment, so the nested map has
    // to be replaced rather than mutated in place or the write never lands.
    function setMonitorScale(key, scale) {
        var next = {};
        for (var k in adapter.monitorScales)
            next[k] = adapter.monitorScales[k];
        next[key] = scale;
        adapter.monitorScales = next;
    }

    Process {
        // FileView will not create intermediate directories.
        running: true
        command: ["mkdir", "-p", root.stateDir]
        onExited: view.reload()
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

        JsonAdapter {
            id: adapter

            property int textSizePx: 12
            property bool stayAwake: false
            property bool barTransparent: false
            // monitor description -> scale
            property var monitorScales: ({})
        }
    }
}
