pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// One overlay per screen, shown on the focused one; the calculator's
// focus-grab arrangement.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow { // qmllint disable uncreatable-type
            id: launcherWindow

            required property var modelData

            readonly property bool current: Launcher.shown && modelData.name === Launcher.screenName

            visible: current
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-launcher"
            WlrLayershell.keyboardFocus: current ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            implicitWidth: view.implicitWidth
            implicitHeight: view.implicitHeight

            HyprlandFocusGrab {
                active: launcherWindow.current
                windows: [launcherWindow]
                onCleared: Launcher.dismiss()
            }

            LcdLauncherView {
                id: view

                anchors.fill: parent
                inputEnabled: launcherWindow.current
            }
        }
    }
}
