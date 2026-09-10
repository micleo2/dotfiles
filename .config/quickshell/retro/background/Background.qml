import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// The wallpaper, one window per output on the background layer, taken from
// the theme in use so a palette change swaps it in the same frame the chips
// recolour. In-process rather than hyprpaper so it cannot come up before the
// lock at session start: the lock surface and this are the one client.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: window

            required property var modelData

            readonly property string path: {
                var p = String(Config.colors.defaultWallpaperPath || "");
                if (p.indexOf("~/") === 0)
                    return Quickshell.env("HOME") + p.substring(1);
                return p;
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
                anchors.fill: parent
                visible: window.path !== ""
                source: window.path !== "" ? "file://" + window.path : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }
}
