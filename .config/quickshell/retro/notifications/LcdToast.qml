pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import "../osd" as Osd
import "../ui" as Ui
import ".."
import "text.js" as TextUtil
import "glyphs.js" as Glyphs

// One notification as a Game & Watch style LCD module, in the OSD's frame:
// hard offset shadow, outlined bezel, dark face. Inside, a pictogram for
// what kind of thing arrived, a character grid with the app and time on the
// top row, the summary on the second (scrolling if it does not fit) and up
// to two rows of body, and a bar of LCD segments draining as the toast's
// life runs out. Critical toasts light in the urgent colour, blink their
// pictogram, and have no bar because they never expire.
//
// Every toast is the same width whatever it says. That is what makes it read
// as a module and not a card.
Item {
    id: root

    required property var notification
    property int columns: 28
    property int bodyRows: 2

    readonly property bool critical: root.notification.urgency === NotificationUrgency.Critical
    readonly property color ink: root.critical ? Config.colors.urgent : Config.colors.text
    readonly property real ghost: 0.12
    readonly property int pad: 18

    readonly property string time: Qt.formatTime(new Date(Notifications.arrivedAt(root.notification)), "HH:mm")
    readonly property string appLabel: TextUtil.fit(TextUtil.appLabel(root.notification.appName, root.notification.desktopEntry), root.columns - root.time.length - 1)
    readonly property string summary: TextUtil.plain(root.notification.summary)
    readonly property var body: TextUtil.wrap(TextUtil.plain(root.notification.body), root.columns, root.bodyRows)
    readonly property var pictogram: Glyphs.pick(root.notification.appName, root.notification.desktopEntry, root.summary, root.notification.urgency, NotificationUrgency.Critical)

    readonly property bool expires: Notifications.expires(root.notification)
    readonly property real remaining: Notifications.remaining(root.notification)
    readonly property bool hovered: hover.hovered

    onHoveredChanged: Notifications.setPaused(root.notification, root.hovered)

    // A critical toast blinks its pictogram, the way an LCD flags an alarm.
    property bool blinkOn: true

    Timer {
        running: root.critical
        interval: 500
        repeat: true
        onTriggered: root.blinkOn = !root.blinkOn
    }

    implicitWidth: bezel.width + 4
    implicitHeight: bezel.height + 4

    Rectangle {
        x: bezel.x + 4
        y: bezel.y + 4
        width: bezel.width
        height: bezel.height
        color: Config.colors.outline
    }

    Rectangle {
        id: bezel

        width: panel.implicitWidth + 2 * root.pad
        height: panel.implicitHeight + 2 * root.pad
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
            spacing: 16

            Osd.PixelGlyph {
                anchors.verticalCenter: parent.verticalCenter
                rows: root.pictogram
                cell: 5
                ghost: root.ghost
                color: root.ink
                opacity: root.critical && !root.blinkOn ? 0.35 : 1
            }

            Column {
                spacing: 6

                CharGrid {
                    id: grid

                    columns: root.columns
                    rows: 2 + root.body.length
                    // The unlit grid stays neutral; only the ink goes urgent.
                    ghost: root.ghost

                    // Row 0: who, and when.
                    Ui.Label {
                        x: 0
                        y: grid.rowY(0)
                        height: grid.cellHeight
                        text: root.appLabel
                        color: root.ink
                        size: grid.size
                        font.letterSpacing: grid.letterSpacing
                        textFormat: Text.PlainText
                    }

                    Ui.Label {
                        x: (grid.columns - root.time.length) * grid.cellWidth
                        y: grid.rowY(0)
                        height: grid.cellHeight
                        text: root.time
                        color: root.ink
                        size: grid.size
                        font.letterSpacing: grid.letterSpacing
                        textFormat: Text.PlainText
                    }

                    // Row 1: the summary, crawling if it overflows.
                    Item {
                        x: 0
                        y: grid.rowY(1)
                        width: grid.width
                        height: grid.cellHeight

                        Ui.MarqueeLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            maxWidth: grid.width
                            text: root.summary
                            color: root.ink
                            size: grid.size
                            letterSpacing: grid.letterSpacing
                        }
                    }

                    // Rows 2+: the body.
                    Repeater {
                        model: root.body

                        Ui.Label {
                            required property string modelData
                            required property int index

                            x: 0
                            y: grid.rowY(2 + index)
                            height: grid.cellHeight
                            text: modelData
                            color: root.ink
                            size: grid.size
                            font.letterSpacing: grid.letterSpacing
                            textFormat: Text.PlainText
                        }
                    }
                }

                Osd.LcdBars {
                    visible: root.expires
                    totalWidth: grid.width
                    segments: 20
                    segmentHeight: 6
                    spacing: 3
                    filled: Math.ceil(root.remaining * segments)
                    ghost: root.ghost
                    color: root.ink
                }
            }
        }

        HoverHandler {
            id: hover

            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton)
                    Notifications.invoke(root.notification);
                else
                    root.notification.dismiss();
            }
        }
    }
}
