import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    property bool active: false
    property var entries: []

    readonly property bool shown: active && entries.length > 0

    readonly property var default_entries: [
        { key: "b", label: "Blender" },
        { key: "d", label: "Discord" },
        { key: "f", label: "FreeCAD" },
        { key: "i", label: "Inkscape" },
        { key: "o", label: "Obsidian" },
        { key: "s", label: "Spotify" },
        { key: "t", label: "Terminal" },
        { key: "y", label: "Yazi" },
        { key: "k", label: "Makera Studio" },
        { key: "p", label: "Photoshop 2024" },
        { key: "m", label: "Messenger" },
        { key: "w", label: "WhatsApp" }
    ]

    IpcHandler {
        target: "appmap"

        // NOTE: function names colliding with `qs ipc` subcommand names
        // (show/call/wait/listen/prop) are hijacked by the CLI parser and
        // never reach the handler. "display" avoids the collision.
        function display(payload: string): void {
            // Payload is {"entries":[...]} — the object envelope keeps the
            // qs 0.3.1 CLI from mangling a bare JSON array argument.
            root.entries = JSON.parse(payload).entries;
            root.active = true;
        }

        function preview(): void {
            if (root.entries.length === 0)
                root.entries = root.default_entries;
            root.active = !root.active;
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "submap")
                root.active = event.data === "appmap";
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlayWindow

            required property var modelData

            visible: root.shown
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"

            anchors {
                bottom: true
                left: true
                right: true
            }
            implicitHeight: grid.implicitHeight + 40

            Grid {
                id: grid

                x: Math.max(0, (parent.width - width) / 2)
                y: parent.height - height - 20
                columns: 4
                spacing: 16

                Repeater {
                    model: root.entries

                    Text {
                        font.pixelSize: 20
                        color: "white"
                        text: modelData.key + "\n" + modelData.label
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}