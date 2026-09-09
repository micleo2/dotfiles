import QtQuick
import "../ui" as Ui
import ".."

// The LCD module's frame: a hard offset shadow, an outlined bezel in the
// base colour and, inset, the dark face the segments sit on. Children are
// centred on the face and the bezel sizes itself to them plus `pad`.
Rectangle {
    id: root

    property int pad: 18
    // How far the shadow reaches past the box. An owner sizing a surface
    // around the bezel adds this so the shadow is not clipped.
    readonly property int shadowOffset: shadow.offset

    default property alias content: slot.data

    implicitWidth: slot.childrenRect.width + 2 * root.pad
    implicitHeight: slot.childrenRect.height + 2 * root.pad
    color: Config.colors.base
    border.width: 2
    border.color: Config.colors.outline

    Ui.Shadow {
        id: shadow

        offset: 4
    }

    // The LCD face.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        color: Config.colors.shadow
        border.width: 2
        border.color: Config.colors.outline
    }

    Item {
        id: slot

        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}
