import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Scope {
    property bool osdVisible: false

    Connections {
        function onBrightnessChanged() {
            osdVisible = true;
            hideTimer.restart();
        }

        target: Brightness
    }

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: osdVisible = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWindow

            required property var modelData

            visible: osdVisible
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"
            implicitHeight: 160

            anchors {
                bottom: true
                left: true
                right: true
            }

            // Bucket container — centered, 35% screen width
            Item {
                id: bucketWrapper

                property int filledCount: Math.round(Brightness.percent / 10)
                property real flare: 14

                width: osdWindow.width * 0.35
                height: 72
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 80

                Canvas {
                    property int filledCount: bucketWrapper.filledCount

                    anchors.fill: parent
                    onFilledCountChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var f = bucketWrapper.flare;
                        var bw = 4;
                        var gap = 5;
                        var inLeft = gap;
                        var inRight = gap;
                        var segArea = width - inLeft - inRight;
                        var segW = (segArea - gap * 9) / 10;
                        // Bucket body fill
                        ctx.fillStyle = "#000000";
                        ctx.beginPath();
                        ctx.moveTo(0, f);
                        ctx.lineTo(width, 0);
                        ctx.lineTo(width, height);
                        ctx.lineTo(0, height - f);
                        ctx.closePath();
                        ctx.fill();
                        // Trapezoid segments
                        for (var i = 0; i < 10; i++) {
                            var x1 = inLeft + i * (segW + gap);
                            var x2 = x1 + segW;
                            var topAtX1 = f * (1 - x1 / width) + gap;
                            var topAtX2 = f * (1 - x2 / width) + gap;
                            var botAtX1 = height - f * (1 - x1 / width) - gap;
                            var botAtX2 = height - f * (1 - x2 / width) - gap;
                            ctx.fillStyle = i < filledCount ? "#ffffff" : "#000000";
                            ctx.beginPath();
                            ctx.moveTo(x1, topAtX1);
                            ctx.lineTo(x2, topAtX2);
                            ctx.lineTo(x2, botAtX2);
                            ctx.lineTo(x1, botAtX1);
                            ctx.closePath();
                            ctx.fill();
                            ctx.strokeStyle = "#000000";
                            ctx.lineWidth = 1;
                            ctx.stroke();
                        }
                        // Left wall
                        ctx.strokeStyle = "#000000";
                        ctx.lineWidth = bw;
                        ctx.beginPath();
                        ctx.moveTo(bw / 2, f);
                        ctx.lineTo(bw / 2, height - f);
                        ctx.stroke();
                        // Top line
                        ctx.beginPath();
                        ctx.moveTo(0, f);
                        ctx.lineTo(width, 0);
                        ctx.stroke();
                        // Bottom line
                        ctx.beginPath();
                        ctx.moveTo(0, height - f);
                        ctx.lineTo(width, height);
                        ctx.stroke();
                    }
                }

            }

        }

    }

}
