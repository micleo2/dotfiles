import QtQuick
import ".."

// A Material Symbols glyph, addressed by name via the font's ligatures.
//
// Every glyph in the font is given a full em advance regardless of how wide its
// ink actually is: signal_wifi_4_bar fills all 960 units, while battery_full is
// 400 wide with 280 units of blank on each side. Left alone that reads as one
// chip having noticeably more internal padding than its neighbours, so each
// glyph is trimmed to its own ink extent and shifted back into place.
Item {
    id: root

    property string text: ""
    property int size: Config.settings.bar.fontSize
    property color color: Config.colors.text

    implicitWidth: root.text === "" ? 0 : Math.ceil(metrics.tightBoundingRect.width)
    implicitHeight: label.implicitHeight

    TextMetrics {
        id: metrics

        font: label.font
        text: root.text
    }

    Text {
        id: label

        // Text paints from the advance origin, so the left side bearing has to
        // be cancelled out or the trimmed glyph sits off-centre.
        x: -metrics.tightBoundingRect.x
        anchors.verticalCenter: parent.verticalCenter

        text: root.text
        color: root.color
        renderType: Text.NativeRendering

        font.family: Config.iconFont
        font.pixelSize: root.size
    }
}
