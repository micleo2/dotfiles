import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// A module's window, one per screen: shown on the screen that had focus
// when the module was opened, sized to the one view inside it and centred
// by the compositor. Keyboard focus is on demand and held by a focus grab,
// the popups' arrangement: a press anywhere else clears the grab and closes
// the module.
//
// `module` is the singleton behind it, with `shown`, `screenName` and
// `dismiss()`; the view inside reads `current` for its inputEnabled.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    required property var module
    required property string namespace

    readonly property bool current: root.module.shown && root.modelData.name === root.module.screenName
    // The one item placed inside, which the window is sized to.
    readonly property Item view: contentItem.children.length > 0 ? contentItem.children[0] : null

    visible: root.current
    screen: root.modelData
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.namespace
    WlrLayershell.keyboardFocus: root.current ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    implicitWidth: root.view ? root.view.implicitWidth : 0
    implicitHeight: root.view ? root.view.implicitHeight : 0

    HyprlandFocusGrab {
        active: root.current
        windows: [root]
        onCleared: root.module.dismiss()
    }
}
