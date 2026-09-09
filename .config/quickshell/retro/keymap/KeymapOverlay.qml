pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../ui" as Ui
import ".."

// One window per screen, shown on the focused one (Ui.ModalWindow).
Scope {
    Variants {
        model: Quickshell.screens

        Ui.ModalWindow {
            id: win

            module: Keymap
            namespace: "qs-keymap"

            LcdKeymapView {
                anchors.fill: parent
                inputEnabled: win.current
                maxWidth: win.modelData.width * 0.92
            }
        }
    }
}
