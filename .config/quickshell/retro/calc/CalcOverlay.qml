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

            module: Calculator
            namespace: "qs-calc"

            LcdCalcView {
                anchors.fill: parent
                inputEnabled: win.current
            }
        }
    }
}
