pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// The calculator's window: one overlay per screen, shown on the one that
// had focus when it was opened, sized to the module and centred by the
// compositor. Keyboard focus is on demand and held by a focus grab, the
// popups' arrangement: a press anywhere else clears the grab and closes it.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: calcWindow

            required property var modelData

            readonly property bool current: Calculator.shown && modelData.name === Calculator.screenName

            visible: current
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-calc"
            WlrLayershell.keyboardFocus: current ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            implicitWidth: view.implicitWidth
            implicitHeight: view.implicitHeight

            HyprlandFocusGrab {
                active: calcWindow.current
                windows: [calcWindow]
                onCleared: Calculator.dismiss()
            }

            LcdCalcView {
                id: view

                anchors.fill: parent
                inputEnabled: calcWindow.current
            }
        }
    }
}
