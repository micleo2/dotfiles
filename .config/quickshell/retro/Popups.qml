pragma Singleton

import QtQuick
import Quickshell

// Which popup is open, shell-wide.
//
// One at a time, across every screen: opening a popup simply displaces whatever
// was open, and each Popup watches this to know whether it is the current one.
Singleton {
    property var active: null

    // Last pointer position any popup control saw, in scene coordinates.
    // Hover only moves the cursor on real motion: Qt re-sends hover when
    // content scrolls under a still pointer, which is exactly what keyboard
    // navigation does, and that must not hand the cursor back to the mouse.
    property point pointer: Qt.point(-1, -1)

    function pointerMoved(scene) {
        if (scene.x === pointer.x && scene.y === pointer.y)
            return false;
        pointer = scene;
        return true;
    }
}
