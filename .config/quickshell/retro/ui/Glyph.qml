import QtQuick
import ".."

// A Material Symbols glyph, addressed by name via the font's ligatures.
//
// Every glyph in the font is given a full em advance regardless of how wide its
// ink actually is: signal_wifi_4_bar fills all 960 units, while battery_full is
// 400 wide with 280 units of blank on each side. The ink is measured and the
// glyph shifted back into place; how much room it then takes depends on `slot`.
// Zero, the popups' default, trims to the ink so a list column lines up on the
// glyph itself. The bar chips hand in one fixed slot and the ink is centred in
// it: ten chips of ten widths read as uneven however equal their padding.
Item {
    id: root

    property string text: ""
    property int size: Config.settings.bar.fontSize
    property color color: Config.colors.text
    property int slot: 0

    readonly property int ink: Math.ceil(metrics.tightBoundingRect.width)

    implicitWidth: root.text === "" ? 0 : Math.max(root.slot, root.ink)
    implicitHeight: label.implicitHeight

    TextMetrics {
        id: metrics

        font: label.font
        text: root.text
    }

    Text {
        id: label

        // Text paints from the advance origin, so the left side bearing has to
        // be cancelled out or the glyph sits off-centre.
        x: -metrics.tightBoundingRect.x + Math.floor((root.width - root.ink) / 2)
        anchors.verticalCenter: parent.verticalCenter

        text: root.text
        color: root.color
        renderType: Text.NativeRendering

        font.family: Config.iconFont
        font.pixelSize: root.size
    }
}
