pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// The Wayland side of the submap cheat sheet: one overlay per screen at the
// bottom centre, shown while Hyprland is in the submap the last `display`
// call named. The module itself is LcdSubmapView.
Scope {
    id: root

    property bool active: false
    property var entries: []
    property string submapName: ""

    readonly property bool shown: active && entries.length > 0

    readonly property var default_entries: [
        {
            key: "t",
            label: "testing"
        },
        {
            key: "SHIFT+S",
            label: "shutdown"
        },
        {
            key: "SUPER+A",
            label: "apps"
        },
    ]

    IpcHandler {
        target: "submap"

        // NOTE: function names colliding with `qs ipc` subcommand names
        // (show/call/wait/listen/prop) are hijacked by the CLI parser and
        // never reach the handler. "display" avoids the collision.
        function display(payload: string): void {
            // Payload is {"submap":"...","entries":[...]} — the object
            // envelope keeps the qs 0.3.1 CLI from mangling a bare JSON
            // array argument.
            const data = JSON.parse(payload);
            root.submapName = data.submap ?? "";
            root.entries = data.entries;
            root.active = true;
        }

        function preview(): void {
            if (root.entries.length === 0) {
                root.entries = root.default_entries;
                root.submapName = "preview";
            }
            root.active = !root.active;
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "submap")
                root.active = root.submapName !== "" && event.data === root.submapName;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: overlayWindow

            required property var modelData

            visible: root.shown
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-submap-overlay"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"

            // Anchored to the bottom only, so the compositor centres it and
            // the surface is no wider than the module: the pointer reaches
            // whatever is beside it.
            anchors.bottom: true
            // PanelWindow's margins group is not described in Quickshell's
            // type information, so qmllint cannot see it; it works at
            // runtime.
            // qmllint disable unqualified unresolved-type
            margins.bottom: 20
            // qmllint enable unqualified unresolved-type

            implicitWidth: view.implicitWidth
            implicitHeight: view.implicitHeight

            LcdSubmapView {
                id: view

                anchors.fill: parent
                entries: root.entries
                submapName: root.submapName
            }
        }
    }
}
