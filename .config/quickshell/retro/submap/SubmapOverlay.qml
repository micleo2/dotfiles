pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

Scope {
    id: root

    property bool active: false
    property var entries: []
    property string submapName: ""

    readonly property bool shown: active && entries.length > 0

    readonly property var sortedEntries: entries.slice().sort((a, b) => String(a.label).localeCompare(String(b.label)))

    // Each column holds up to 4 entries, sliced sequentially out of the
    // sorted list, so the alphabet runs top-to-bottom down one column and
    // then continues in the next — like `ls` output.
    readonly property int perColumn: 4
    readonly property var entryGroups: {
        const out = [];
        for (let i = 0; i < root.sortedEntries.length; i += root.perColumn)
            out.push(root.sortedEntries.slice(i, i + root.perColumn));
        return out;
    }

    readonly property var default_entries: [
        {
            key: "t",
            label: "testing",
            icon: "blender"
        },
    ]

    function escapeHtml(text) {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Highlight the trigger key inside the label: a single-character key is
    // matched case-sensitively anywhere in the label (k -> ma[k]era), a longer
    // key still only matches as a case-insensitive prefix. Anything else falls
    // back to the explicit "key->label" form.
    function styledLabel(key, label) {
        const red = k => "<font color=\"red\">" + escapeHtml(k) + "</font>";

        if (key.length === 1) {
            const at = label.indexOf(key);
            if (at >= 0)
                return escapeHtml(label.substring(0, at)) + red(key) + escapeHtml(label.substring(at + 1));
        } else if (label.toLowerCase().startsWith(key.toLowerCase())) {
            return red(label.substring(0, key.length)) + escapeHtml(label.substring(key.length));
        }

        return red(key) + "-&gt;" + escapeHtml(label);
    }

    // Same lookup chain as services/FocusedWindow.qml: try the name as-is, then the
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
            if (root.entries.length === 0)
                root.entries = root.default_entries;
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
                    radius: 2
                    color: "#99000000"
                }

                Row {
                    id: grid

                    x: 30
                    y: 24
                    // Half of the 36px column gap; a divider occupies the
                    // other half, so the rule lands centered between columns.
                    spacing: 18

                    Repeater {
                        id: columnRepeater

                        model: root.entryGroups

                        Row {
                            id: entryColumn
                            required property var modelData
                            required property int index

                            readonly property var groupEntries: modelData

                            spacing: 18

                            Column {
                                id: column

                                spacing: 6

                                Repeater {
                                    model: entryColumn.groupEntries

                                    Row {
                                        id: entry
                                        required property var modelData

                                        readonly property string key: String(modelData.key)
                                        readonly property string label: String(modelData.label)

                                        readonly property string icon: root.iconPath(modelData.icon)

                                        Text {
                                            text: root.styledLabel(entry.key, entry.label)
                                            textFormat: Text.StyledText
                                            color: "white"
                                            font.pointSize: 18
                                            font.family: Config.mainFont
                                        }

                                        // Text {
                                        //     text: "<font color='red'>" + modelData.key + "</font>->"
                                        //     color: "white"
                                        //     font.pointSize: 18
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

                            // A column is only ever short when it is the last
                            // one, and the last one draws no rule, so the
                            // sibling Column always spans a full stack here.
                            // Binding to the enclosing Row's height instead
                            // would be circular.
                            Rectangle {
                                width: 1
                                height: column.implicitHeight
                                color: "#33ffffff"
                                visible: entryColumn.index < columnRepeater.count - 1
                            }
                        }
                    }
                }
            }
        }
    }
}
