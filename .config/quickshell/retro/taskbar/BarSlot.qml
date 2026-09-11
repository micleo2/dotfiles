import QtQuick
import QtQuick.Layouts
import "../services"

// One widget's place in the bar, built only while its module is on.
//
// Hiding a chip is not enough to make it free: a hidden Item still holds
// every binding, timer and process it declares, and its popup and IPC
// handler with them. This is a Loader, so a widget whose module is off does
// not exist, and there is nothing of it to run. Switching the module on
// builds it fresh, and off tears it down, popup included.
//
// The widget's own `available` (its hardware test) decides whether the slot
// takes room. That is read rather than the widget's `visible`, which is an
// effective value and goes false whenever an ancestor hides, latching a
// row that hides on it (see BarModules).
Loader {
    id: root

    required property string module

    readonly property bool available: root.item !== null && root.item.available === true

    active: Modules.on(root.module)
    visible: root.available
    Layout.fillHeight: true
}
