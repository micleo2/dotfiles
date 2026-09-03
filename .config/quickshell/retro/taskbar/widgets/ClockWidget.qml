import "../.."
import QtQuick
import "../../services"

Text {
    text: Time.time
    color: Config.colors.text
    font.pixelSize: Config.settings.bar.fontSize
    font.family: Config.mainFont
}
