import ".."
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        anchors.centerIn: parent

        Text {
            id: iconText

            text: Weather.icon
            color: Config.colors.text
            font.pixelSize: Math.round(Config.settings.bar.fontSize * 0.9)
            font.family: mainFont.name
            anchors.verticalCenter: parent.verticalCenter
            visible: false
        }

        MultiEffect {
            source: iconText
            width: iconText.implicitWidth
            height: iconText.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            saturation: -1
            contrast: 0.7
        }

        Text {
            text: Weather.temp
            color: Config.colors.text
            font.pixelSize: Config.settings.bar.fontSize
            font.family: mainFont.name
            anchors.verticalCenter: parent.verticalCenter
        }

    }

}
