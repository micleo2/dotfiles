pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Io
import "../ui" as Ui
import ".."

Item {
    id: root

    required property var barScreen
    required property bool primary

    // Touchpads send a stream of sub-notch deltas rather than one event per
    // detent, so the remainder has to be carried between events or a slow drag
    // does nothing and a fast one jumps.
    property real wheelAccumulator: 0

    readonly property int stepPercent: Volume.stepPercent

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0

    function handleWheel(event) {
        var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
        // One detent is 120 units. Clamp so a flung touchpad cannot deliver a
        // single enormous event.
        root.wheelAccumulator += Math.max(-120, Math.min(120, delta));
        while (Math.abs(root.wheelAccumulator) >= 120) {
            var direction = root.wheelAccumulator > 0 ? 1 : -1;
            root.wheelAccumulator -= direction * 120;
            Volume.adjust(direction * root.stepPercent / 100);
        }
    }

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                Volume.toggleMute();
            else
                popup.toggle();
        }
        onScrolled: (event) => root.handleWheel(event)

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24

            Image {
                id: speaker

                anchors.fill: parent
                // The hand-drawn source is 16x16 and has always been drawn at 24,
                // i.e. upscaled 1.5x with nearest-neighbour. sourceSize pins the
                // decode to native so the upscale stays crisp rather than resampled.
                source: Volume.muted ? "assets/muted.png" : "assets/unmuted.png"
                sourceSize.width: 16
                sourceSize.height: 16
                smooth: false
                // Drawn through the colourised copy below, so the black ink
                // follows the palette's text colour on a dark theme.
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: speaker
                colorization: 1
                colorizationColor: Config.colors.text
            }
        }

        Ui.Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: !Volume.muted
            text: Volume.percent + "%"
        }
    }

    Ui.Popup {
        id: popup

        anchorItem: chip
        barScreen: root.barScreen
        cardWidth: 320

        // Only snapshot the device list while someone is looking at it.
        onOpenedChanged: Volume.watching = popup.opened

        Ui.PopupSlider {
            // One block per step of *volume*, so the blocks read as a level
            // rather than as a position: silence lights nothing, and full
            // lights every block. Starting the stops at 0 instead would make
            // the leftmost block the "0%" position and leave it lit at
            // silence, which is what a magnitude bar should never do.
            readonly property var steps: {
                var out = [];
                for (var v = root.stepPercent; v <= 100; v += root.stepPercent)
                    out.push(v);
                return out;
            }

            rowKey: "level"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "level"

            stops: steps
            index: Math.round(Volume.percent / root.stepPercent) - 1
            onMoved: (index) => Volume.setVolume(steps[index] / 100)
        }

        Ui.PopupRow {
            interactive: false
            text: Volume.muted ? "Muted" : "Volume"
            detail: Volume.percent + "%"
        }

        Ui.SectionLabel {
            text: "Output"
        }

        Repeater {
            model: Volume.displaySinks

            Ui.PopupRow {
                required property var modelData

                rowKey: "sink:" + modelData.id
                cursorKey: popup.cursorKey
                onCursorEntered: popup.cursorKey = "sink:" + modelData.id

                glyph: Volume.glyphFor(modelData)
                text: Volume.label(modelData)
                selected: Volume.sink !== null && modelData.id === Volume.sink.id
                onClicked: Volume.setSink(modelData)
            }
        }
    }

    IpcHandler {
        // Bars are instantiated per screen; only the primary one claims the
        // target, or a second monitor collides with it.
        target: "volume"
        enabled: root.primary

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function toggle(): void {
            popup.toggle();
        }

        function open(): void {
            popup.open();
        }

        function close(): void {
            popup.close();
        }

        // Open with the keyboard cursor placed, for the SUPER+T submap
        // (hypr/submap-topbar.lua).
        function focus(): void {
            popup.openWithCursor();
        }

        function mute(): string {
            Volume.toggleMute();
            return Volume.muted ? "muted" : "unmuted";
        }

        function up(): string {
            Volume.adjust(root.stepPercent / 100);
            return Volume.percent + "%";
        }

        function down(): string {
            Volume.adjust(-root.stepPercent / 100);
            return Volume.percent + "%";
        }

        // Switch output by a case-insensitive substring of its label or node
        // name, so it can take a keybind the way omarchy's output-switch does.
        function output(match: string): string {
            var sinks = Volume.candidateSinks;
            var needle = String(match || "").toLowerCase();
            for (var i = 0; i < sinks.length; i++) {
                var node = sinks[i];
                if (Volume.label(node).toLowerCase().indexOf(needle) !== -1 || String(node.name).toLowerCase().indexOf(needle) !== -1) {
                    Volume.setSink(node);
                    return "-> " + Volume.label(node);
                }
            }
            return "no output matching " + match;
        }
    }
}
