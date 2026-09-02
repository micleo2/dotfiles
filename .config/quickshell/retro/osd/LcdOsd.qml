pragma ComponentBehavior: Bound
import ".."
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// The on-screen display: one Game & Watch style LCD panel with two modes,
// volume and brightness. Every segment is always drawn as a faint ghost and
// the live ones are solid, which is what makes it read as an LCD. One window
// and one timer, so a volume change while brightness is up simply swaps the
// panel's contents. Colours come from the palette, so the dark themes get a
// dark LCD for free.
Scope {
    id: osdRoot

    // "volume" or "brightness".
    property string mode: ""
    property bool shown: false

    readonly property bool volume: osdRoot.mode === "volume"
    readonly property int segments: osdRoot.volume ? Volume.segments : Brightness.segments
    readonly property int percent: osdRoot.volume ? Volume.percent : Brightness.percent
    readonly property int filled: Math.round(osdRoot.percent / 100 * osdRoot.segments)
    readonly property bool muted: osdRoot.volume && Volume.muted
    readonly property real ghost: 0.12

    readonly property var sun: ["....#....", ".#.....#.", "...###...", "..#####..", "#.#####.#", "..#####..", "...###...", ".#.....#.", "....#...."]

    function flash(which) {
        osdRoot.mode = which;
        osdRoot.shown = true;
        hideTimer.restart();
    }

    Connections {
        target: Volume

        function onChanged() {
            osdRoot.flash("volume");
        }
    }

    Connections {
        target: Brightness

        function onBrightnessChanged() {
            // A machine with no backend at all should never flash an OSD that
            // reports a brightness nothing is driving.
            if (!Brightness.available)
                return;
            osdRoot.flash("brightness");
        }
    }

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: osdRoot.shown = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: osdWindow

            required property var modelData

            visible: osdRoot.shown
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"
            // Sized from the panel, plus its bottom margin, the shadow and the
            // outline bleed; a fixed height clipped the top of the bezel.
            implicitHeight: bezel.height + bezel.anchors.bottomMargin + 8

            anchors {
                bottom: true
                left: true
                right: true
            }

            // The popup's frame language: hard offset shadow, outlined bezel.
            Rectangle {
                x: bezel.x + 4
                y: bezel.y + 4
                width: bezel.width
                height: bezel.height
                color: Config.colors.outline
            }

            Rectangle {
                id: bezel

                width: panel.implicitWidth + 2 * 18
                height: panel.implicitHeight + 2 * 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 80
                color: Config.colors.base
                border.width: 2
                border.color: Config.colors.outline

                // The LCD face.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 8
                    color: Config.colors.shadow
                    border.width: 2
                    border.color: Config.colors.outline
                }

                Row {
                    id: panel

                    anchors.centerIn: parent
                    spacing: 20

                    // Icon: the hand-drawn speaker at 4x, or a pixel-map sun.
                    Item {
                        width: 64
                        height: 64
                        anchors.verticalCenter: parent.verticalCenter

                        Item {
                            anchors.fill: parent
                            visible: osdRoot.volume

                            Image {
                                id: speaker

                                anchors.fill: parent
                                source: osdRoot.muted ? "../taskbar/assets/muted.png" : "../taskbar/assets/unmuted.png"
                                sourceSize.width: 16
                                sourceSize.height: 16
                                smooth: false
                                // Drawn through the colourised copy below, so
                                // the black ink follows the palette.
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: speaker
                                colorization: 1
                                colorizationColor: Config.colors.text
                            }
                        }

                        PixelGlyph {
                            anchors.centerIn: parent
                            visible: !osdRoot.volume
                            rows: osdRoot.sun
                            cell: 7
                            ghost: osdRoot.ghost
                        }
                    }

                    LcdBars {
                        anchors.verticalCenter: parent.verticalCenter
                        segments: osdRoot.segments
                        filled: osdRoot.muted ? 0 : osdRoot.filled
                        ghost: osdRoot.ghost
                    }

                    // Readout: three seven-segment digits, or MUTE in the
                    // pixel font.
                    Item {
                        width: readout.implicitWidth
                        height: 44
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: readout

                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            opacity: osdRoot.muted ? 0 : 1

                            Repeater {
                                model: 3

                                SevenSegment {
                                    required property int index

                                    // Leading zeros are left as ghosts.
                                    digit: {
                                        var p = osdRoot.percent;
                                        if (index === 0)
                                            return p >= 100 ? Math.floor(p / 100) % 10 : -1;
                                        if (index === 1)
                                            return p >= 10 ? Math.floor(p / 10) % 10 : -1;
                                        return p % 10;
                                    }
                                    ghost: osdRoot.ghost
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: osdRoot.muted
                            text: "MUTE"
                            color: Config.colors.text
                            font.family: Config.mainFont
                            font.pixelSize: 30
                        }
                    }
                }
            }
        }
    }
}
