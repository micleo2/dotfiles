import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

import ".."

Text {
    text: FocusedWindow.application_name
    color: Config.colors.text
    font.pixelSize: Config.settings.bar.fontSize
    font.family: fontMonaco.name
}
