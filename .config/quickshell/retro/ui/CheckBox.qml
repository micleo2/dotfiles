import QtQuick
import ".."

// The 18px square that says "this one is on": PopupToggle's box, and the
// selection marker at the end of a PopupRow, so a toggle and a selected
// row look the same.
Rectangle {
    property bool checked: false

    width: 18
    height: 18
    color: checked ? Config.colors.text : "transparent"
    border.width: 2
    border.color: Config.colors.outline
}
