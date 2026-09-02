import QtQuick
import ".."

// A Label that scrolls in place when it cannot fit: pause, crawl left until
// the tail is shown, pause, crawl back. Constant speed, and only while
// something is actually clipped and the item is on screen; text that fits is
// a plain static label.
//
// Width can be driven two ways: anchor both edges (PopupRow) and the label
// clips to whatever room it is given, or set maxWidth (bar widgets) and the
// item sizes to its text up to that cap.
Item {
    id: root

    property alias text: label.text
    property alias underline: label.font.underline
    // Negative means "no cap": width comes from anchors alone.
    property real maxWidth: -1

    readonly property real overflow: Math.max(0, label.implicitWidth - width)

    implicitWidth: root.maxWidth >= 0 ? Math.min(label.implicitWidth, root.maxWidth) : label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: true

    Label {
        id: label

        SequentialAnimation on x {
            running: root.overflow > 0 && root.visible
            loops: Animation.Infinite

            PauseAnimation {
                duration: 1200
            }

            NumberAnimation {
                to: -root.overflow
                // px per second, not a fixed duration, so long names do not
                // whip past faster than short ones.
                duration: root.overflow * 25
            }

            PauseAnimation {
                duration: 1200
            }

            NumberAnimation {
                to: 0
                duration: root.overflow * 25
            }
        }
    }
}
