import QtQuick
import QtQuick.Layouts

import ".."

RowLayout {
    id: volWidgetLayout
    spacing: 1

    Rectangle {
        height: 24
        width: height
        color: "transparent"
        Image {
            source: Volume.muted ? "./assets/muted.png" : "./assets/unmuted.png"
            anchors.fill: parent
            sourceSize.width: 16
            sourceSize.height: 16
        }
    }

    Text {
        visible: Volume.muted === false
        text: Volume.volume
        color: Config.colors.text
        font.pixelSize: Config.settings.bar.fontSize
        font.family: mainFont.name
    }
}
