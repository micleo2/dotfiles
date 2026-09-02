import QtQuick
import ".."

// Body text in the shell's pixel font, at the one text size.
Text {
    id: root

    property int size: Config.settings.bar.fontSize

    color: Config.colors.text
    verticalAlignment: Text.AlignVCenter

    font.family: Config.mainFont
    font.pixelSize: root.size
}
