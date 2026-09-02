pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// The toast stack: one overlay per screen, top right under the bar, newest
// on top. The surface covers the whole output and is click-through except
// over the column — sized to the column instead, the compositor briefly
// scaled a stale buffer every time a toast came or went and the modules
// stretched. Passive: no keyboard focus, no exclusive zone.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: toastWindow

            required property var modelData

            visible: Notifications.popups.length > 0
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-notifications"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: column
            }

            Column {
                id: column

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Config.settings.bar.height + 12
                anchors.rightMargin: 12
                spacing: 12

                Repeater {
                    // Diffed by identity, so adding or removing a toast
                    // leaves the others' delegates (and their marquees and
                    // power-on flash) alone.
                    model: ScriptModel {
                        values: Notifications.popups
                    }

                    LcdToast {
                        required property var modelData

                        notification: modelData
                    }
                }
            }
        }
    }
}
