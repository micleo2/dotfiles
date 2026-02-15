import QtQuick
import ".."

Text {
    text: Time.time
    color: Config.colors.text
    font.pixelSize: Config.settings.bar.fontSize
    font.family: mainFont.name
}
