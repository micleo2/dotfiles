pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// The launcher's window: one overlay per screen, shown on the one that had
// focus when it was opened, sized to the module and centred by the
// compositor. Keyboard focus is on demand and held by a focus grab, the
// calculator's arrangement: a press anywhere else clears the grab and
// closes it, which answers an open dmenu with nothing.
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
