pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// The keyboard layout viewer's window: one overlay per screen, shown on
// the one that had focus when it was opened, sized to the module and
// centred by the compositor. Keyboard focus is on demand and held by a
// focus grab, the calculator's arrangement: the layer keys work while it
// is up, and a press anywhere else clears the grab and closes it.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: keymapWindow

            required property var modelData

            readonly property bool current: Keymap.shown && modelData.name === Keymap.screenName

            visible: current
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-keymap"
            WlrLayershell.keyboardFocus: current ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            implicitWidth: view.implicitWidth
            implicitHeight: view.implicitHeight

            HyprlandFocusGrab {
                active: keymapWindow.current
                windows: [keymapWindow]
                onCleared: Keymap.dismiss()
            }

            LcdKeymapView {
                id: view

                anchors.fill: parent
                inputEnabled: keymapWindow.current
                maxWidth: keymapWindow.modelData.width * 0.92
            }
        }
    }
}
