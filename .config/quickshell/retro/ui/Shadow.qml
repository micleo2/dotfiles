import QtQuick
import ".."

// The hard offset drop shadow every frame in the shell shares: the parent's
// silhouette pushed down and right by `offset`, no blur, in the palette's
// dropShadow tone. Drop it inside the frame it shadows; a negative z paints
// it beneath the parent's own fill, so it needs no ordering against siblings.
Rectangle {
    // Distance down and right. 2 for chips, 4 for popups and LCD frames.
    property int offset: 4
    // How far the visible frame extends past the parent's bounds, for frames
    // whose 2px border is drawn outside the item (Chip, Popup). 0 when the
    // border is inside, as on a Rectangle with border.width.
    property int bleed: 0

    z: -1
    x: offset - bleed
    y: offset - bleed
    width: parent ? parent.width + 2 * bleed : 0
    height: parent ? parent.height + 2 * bleed : 0
    color: Config.colors.dropShadow
}
