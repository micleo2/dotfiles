pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../../ui" as Ui
import "../.."
import "../../services"

Ui.Chip {
    id: root

    required property var barScreen
    required property bool primary

    readonly property int stepPercent: Volume.stepPercent

    interactive: true

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton)
            Volume.toggleMute();
        else
            popup.toggle();
    }
    onStepped: (direction) => Volume.adjust(direction * root.stepPercent / 100)

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: Config.settings.bar.iconSlot
        height: Config.settings.bar.iconSlot

        Image {
            id: speaker

            anchors.fill: parent
            // The hand-drawn source is 16x16 and has always been drawn at 24,
            // i.e. upscaled 1.5x with nearest-neighbour. sourceSize pins the
            // decode to native so the upscale stays crisp rather than resampled.
            source: Volume.muted ? "../assets/muted.png" : "../assets/unmuted.png"
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

    Ui.Popup {
        id: popup

        anchorItem: root
        barScreen: root.barScreen
        cardWidth: 320

        // Only snapshot the device list while someone is looking at it.
        onOpenedChanged: Volume.watching = popup.opened

        // One block per step of *volume*, so the blocks read as a level
        // rather than as a position: silence lights nothing, and full lights
        // every block (percentStops).
        Ui.PopupSlider {
            rowKey: "level"

            stops: percentStops(root.stepPercent)
            index: percentIndex(Volume.percent, root.stepPercent)
            onMoved: (index) => Volume.setVolume(stops[index] / 100)
        }

        Ui.PopupRow {
            interactive: false
            text: Volume.muted ? "Muted" : "Volume"
            detail: Volume.percent + "%"
        }

        Ui.SectionLabel {
            visible: Volume.displayApps.length > 0
            text: "Apps"
        }

        Repeater {
            model: Volume.displayApps

            // Two cursor stops per app: the row (Enter or a click mutes it)
            // and the slider under it (h/l or a drag sets its level).
            Column {
                id: app

                required property var modelData

                width: parent ? parent.width : 0

                Ui.PopupRow {
                    rowKey: "app:" + app.modelData.key

                    glyph: "graphic_eq"
                    text: Volume.appTitle(app.modelData) !== "" ? app.modelData.label + " - " + Volume.appTitle(app.modelData) : app.modelData.label
                    detail: Volume.appMuted(app.modelData) ? "Muted" : Math.round(Volume.appVolume(app.modelData) * 100) + "%"
                    onClicked: Volume.toggleAppMute(app.modelData)
                }

                Ui.PopupSlider {
                    rowKey: "appvol:" + app.modelData.key

                    implicitHeight: 16
                    stops: percentStops(root.stepPercent)
                    index: percentIndex(Volume.appVolume(app.modelData) * 100, root.stepPercent)
                    onMoved: (index) => Volume.setAppVolume(app.modelData, stops[index] / 100)
                }
            }
        }

        Ui.SectionLabel {
            text: "Output"
        }

        Repeater {
            model: Volume.displaySinks

            Ui.PopupRow {
                required property var modelData

                rowKey: "sink:" + modelData.id

                glyph: Volume.glyphFor(modelData)
                text: Volume.label(modelData)
                selected: Volume.sink !== null && modelData.id === Volume.sink.id
                onClicked: Volume.setSink(modelData)
            }
        }
    }

    Ui.PopupIpc {
        target: "volume"
        enabled: root.primary

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
