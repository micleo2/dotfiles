pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Facts about this machine's power hardware, read from UPower.
//
// `isLaptop` is the one fact the module gating needs. UPower resolves
// asynchronously a moment after launch, so it reads false briefly on every
// start; everything downstream binds to it and settles.
//
// The device helpers are shared by everything that reads a battery (the
// laptop chip, its history plot, the controller list) so they all agree on
// what "charging" means and on the 0-100 scale: UPower reports a 0-1
// fraction.
Singleton {
    id: root

    readonly property var displayDevice: UPower.displayDevice
    readonly property bool isLaptop: root.displayDevice !== null && root.displayDevice.isLaptopBattery

    function percent(device) {
        return device ? Math.round(device.percentage * 100) : 0;
    }

    function charging(device) {
        return !!device && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge);
    }

    function full(device) {
        return !!device && device.state === UPowerDeviceState.FullyCharged;
    }

    // The first UPower device of `type` that `accept` takes, or null. Reads
    // the device list inside the caller's binding, so the result follows it.
    function findDevice(type, accept) {
        var list = UPower.devices.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].type === type && accept(list[i]))
                return list[i];
        }
        return null;
    }
}
