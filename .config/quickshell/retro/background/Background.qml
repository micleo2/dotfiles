import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// The wallpaper, one window per output on the background layer, taken from
// the theme in use so a palette change swaps it in the same frame the chips
// recolour. In-process rather than a separate wallpaper daemon so it cannot
// come up before the lock at session start: the lock surface and this are the
// one client.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: window

            required property var modelData

            // Relative to the config, so the checkout carries its wallpapers.
            readonly property string path: {
                var p = String(Config.colors.defaultWallpaperPath || "");
                if (p === "" || p.indexOf("/") === 0)
                    return p;
                if (p.indexOf("~/") === 0)
                    return Quickshell.env("HOME") + p.substring(1);
                return Quickshell.shellPath(p);
            }

            screen: modelData
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "qs-background"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: Config.colors.base

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Image {
                id: image

                anchors.fill: parent
                visible: window.path !== ""
                source: window.path !== "" ? "file://" + window.path : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Pixel art is authored well under the panel's size, and
                // bilinear scaling turns it to mush; nearest keeps a 2x or 3x
                // step pixel-exact. Anything near native is smoothed as usual.
                smooth: image.sourceSize.width === 0 || image.sourceSize.width * 1.5 > window.width * window.screen.devicePixelRatio
            }
        }
    }
}
