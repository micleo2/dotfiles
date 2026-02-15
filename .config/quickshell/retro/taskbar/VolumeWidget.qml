import QtQuick
import ".."

Text {
    text: "| " + Volume.volume
    color: Config.colors.text
    font.pixelSize: Config.settings.bar.fontSize
    font.family: mainFont.name
}
