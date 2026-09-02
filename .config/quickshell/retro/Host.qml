pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Is this machine a laptop? The one hardware fact the module gating needs.
//
// UPower resolves asynchronously a moment after launch, so this reads false
// briefly on every start; everything downstream binds to it and settles.
Singleton {
    id: root

    readonly property var displayDevice: UPower.displayDevice
    readonly property bool isLaptop: root.displayDevice !== null && root.displayDevice.isLaptopBattery
}
