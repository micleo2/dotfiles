import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property bool active: false
    property var entries: []

    readonly property bool shown: active && entries.length > 0

    readonly property var default_entries: [
        {
            key: "b",
            label: "Blender",
            icon: "blender"
        },
        {
            key: "d",
            label: "Discord",
            icon: "discord"
        },
        {
            key: "f",
            label: "FreeCAD",
            icon: "org.freecad.FreeCAD"
        },
        {
            key: "i",
            label: "Inkscape",
            icon: "org.inkscape.Inkscape"
        },
        {
            key: "o",
            label: "Obsidian",
            icon: "obsidian"
        },
        {
            key: "s",
            label: "Spotify",
            icon: "spotify-launcher"
        },
        {
            key: "t",
            label: "Terminal",
            icon: "kitty"
        },
        {
            key: "y",
            label: "Yazi",
            icon: "yazi"
        },
        {
            key: "k",
            label: "MS",
            icon: "bottles-MakeraStudio-MakeraStudio"
        },
        {
            key: "p",
            label: "PS",
            icon: "bottles-Photoshop-2024-Photoshop"
        },
        {
            key: "m",
            label: "Messenger",
            icon: "messenger"
        },
        {
            key: "w",
            label: "WhatsApp",
            icon: "whatsapp"
        }
    ]

    // Same lookup chain as FocusedWindow.qml: try the name as-is, then the
    // last dot segment (reverse-DNS ids ship their icon under the short name).
    function iconPath(name) {
        if (name === undefined || name === null || name === "")
            return "";
        const direct = Quickshell.iconPath(name, true);
        if (direct !== "")
            return direct;
        const segments = name.split(".");
        return Quickshell.iconPath(segments[segments.length - 1].toLocaleLowerCase(), true);
    }

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
            implicitHeight: card.implicitHeight + 40

            Item {
                id: card

                x: Math.max(0, (parent.width - width) / 2)
                y: parent.height - height - 20

                implicitWidth: grid.implicitWidth + 60
                implicitHeight: grid.implicitHeight + 48

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: "#99000000"
                }

                Grid {
                    id: grid

                    x: 30
                    y: 24
                    columns: 4
                    spacing: 16

                    Repeater {
                        model: root.entries

                        Row {
                            required property var modelData

                            spacing: 10

                            readonly property string icon: root.iconPath(modelData.icon)

                            Text {
                                text: "<font color='red'>" + modelData.key + "</font>->" + modelData.label
                                color: "white"
                                font.pointSize: 18
                                font.family: mainFont.name
                            }

                            // Text {
                            //     text: modelData.key + " ->"
                            //     color: "red"
                            //     anchors.verticalCenter: parent.verticalCenter
                            //     font.pointSize: 24
                            //     font.family: mainFont.name
                            // }
                            // IconImage {
                            //     implicitSize: 24
                            //     source: icon
                            //     visible: icon !== ""
                            //     anchors.verticalCenter: parent.verticalCenter
                            //     layer.effect: MultiEffect {
                            //         saturation: -1
                            //         contrast: 0.7
                            //     }
                            // }
                            // Text {
                            //     text: modelData.label
                            //     visible: icon === ""
                            //     color: "white"
                            //     anchors.verticalCenter: parent.verticalCenter
                            //     font.pointSize: 24
                            //     font.family: mainFont.name
                            // }

                        }
                    }
                }
            }
        }
    }
}
