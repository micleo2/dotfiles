pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../ui" as Ui
import ".."

Item {
    id: root

    required property var barScreen
    required property bool primary

    // Quickshell.Bluetooth's type descriptions omit these types, so qmllint
    // cannot resolve them; they are fine at runtime.
    readonly property var adapter: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property bool available: Modules.allow("bluetooth", root.adapter !== null)

    readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : [] // qmllint disable unresolved-type
    readonly property int connectedCount: {
        var n = 0;
        for (var i = 0; i < root.devices.length; i++) {
            if (root.devices[i].connected)
                n++;
        }
        return n;
    }

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.available

    // Connected, then paired, then everything else by name.
    //
    // Only devices that have told us a name are listed at all. That is omarchy's
    // trick and it is the reason its list holds still: a device whose sort key
    // can still change is simply not shown yet, so nothing already on screen
    // ever has to move when BlueZ resolves a name a second later. It also drops
    // the anonymous passers-by that made up most of a scan.
    readonly property var sorted: {
        var list = [];
        for (var i = 0; i < root.devices.length; i++) {
            var device = root.devices[i];
            if (root.named(device) || device.connected || device.paired || device.bonded)
                list.push(device);
        }
        list.sort(function (a, b) {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            return root.label(a).localeCompare(root.label(b));
        });
        return list;
    }

    // The Repeater is fed this, and it is only replaced when the *order* really
    // changes. `sorted` re-evaluates on every BlueZ property update — of which
    // there are many per second during a scan — and handing a Repeater a fresh
    // array each time destroys and rebuilds every delegate for nothing.
    property var displayDevices: []

    function addressesOf(list) {
        var out = [];
        for (var i = 0; i < list.length; i++)
            out.push(list[i].address);
        return out.join(",");
    }

    onSortedChanged: {
        if (root.addressesOf(root.sorted) !== root.addressesOf(root.displayDevices))
            root.displayDevices = root.sorted;
    }

    // BlueZ exposes two names: Name (what the device advertised, read-only) and
    // Alias (a writable override). Prefer the advertised name, fall back to the
    // alias so a rename the user made in blueman is honoured, then the address.
    function label(device) {
        var name = String(device.deviceName || device.name || "").trim();
        return name !== "" ? name : device.address;
    }

    function normalizedAddress(text) {
        return String(text || "").replace(/[^0-9a-z]/gi, "").toLowerCase();
    }

    // A non-empty alias is not proof of a real name: for anything that never
    // advertised one, BlueZ synthesises the alias from the address itself
    // ("40-C7-3C-62-7A-CC"), so that has to be compared away.
    function named(device) {
        if (String(device.deviceName || "").trim() !== "")
            return true;
        var alias = String(device.name || "").trim();
        if (alias === "")
            return false;
        return root.normalizedAddress(alias) !== root.normalizedAddress(device.address);
    }

    function activate(device) {
        if (device.connected)
            device.disconnect();
        else if (device.paired || device.bonded)
            device.connect();
        else
            device.pair();
    }

    function setPower(value) {
        if (!root.adapter)
            return;
        root.adapter.enabled = value;
        if (value)
            rfkillGuard.restart();
    }

    Timer {
        id: rfkillGuard

        // BlueZ cannot power on through an rfkill soft block, and the adapter
        // just stays disabled with no error. Omarchy shells out to
        // omarchy-bluetooth-power for exactly this reason; this is the same
        // recovery, only attempted once and only when the direct route failed.
        interval: 1500
        onTriggered: {
            if (root.adapter && !root.adapter.enabled) {
                Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
                retryPower.restart();
            }
        }
    }

    Timer {
        id: retryPower

        interval: 400
        onTriggered: {
            if (root.adapter)
                root.adapter.enabled = true;
        }
    }

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.setPower(!(root.adapter && root.adapter.enabled));
            else
                popup.toggle();
        }

        Ui.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.adapter && root.adapter.enabled ? 1 : 0.5
            text: {
                if (!root.adapter || !root.adapter.enabled)
                    return "bluetooth_disabled";
                if (root.adapter.discovering)
                    return "bluetooth_searching";
                return root.connectedCount > 0 ? "bluetooth_connected" : "bluetooth";
            }
        }

        Ui.Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.connectedCount > 1
            text: root.connectedCount
        }
    }

    Ui.Popup {
        id: popup

        anchorItem: chip
        barScreen: root.barScreen

        // Discovery burns power and floods the list; only scan while visible.
        onOpenedChanged: {
            if (root.adapter && root.adapter.enabled)
                root.adapter.discovering = popup.opened;
        }

        Ui.PopupToggle {
            rowKey: "power"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "power"

            text: "Bluetooth"
            checked: root.adapter ? root.adapter.enabled : false
            onToggled: (value) => root.setPower(value)
        }

        Ui.PopupToggle {
            rowKey: "scan"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "scan"

            text: "Scanning"
            enabled: root.adapter ? root.adapter.enabled : false
            checked: root.adapter ? root.adapter.discovering : false
            onToggled: (value) => {
                if (root.adapter)
                    root.adapter.discovering = value;
            }
        }

        Ui.SectionLabel {
            text: "Devices"
        }

        Repeater {
            model: root.displayDevices

            Ui.PopupRow {
                required property var modelData

                rowKey: modelData.address
                cursorKey: popup.cursorKey
                onCursorEntered: popup.cursorKey = modelData.address

                glyph: modelData.connected ? "bluetooth_connected" : "bluetooth"
                text: root.label(modelData)
                detail: {
                    if (modelData.state === BluetoothDeviceState.Connecting)
                        return "connecting";
                    if (modelData.pairing)
                        return "pairing";
                    if (modelData.connected && modelData.batteryAvailable)
                        return Math.round(modelData.battery * 100) + "%";
                    if (modelData.paired)
                        return "paired";
                    return "";
                }
                selected: modelData.connected
                busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
                onClicked: root.activate(modelData)
                onRightClicked: {
                    if (modelData.paired || modelData.bonded)
                        modelData.forget();
                }
            }
        }
    }

    IpcHandler {
        // Bars are instantiated per screen; only the primary one
        // claims the target, or a second monitor collides with it.
        target: "bluetooth"
        enabled: root.primary

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by
        // the `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function toggle(): void {
            popup.toggle();
        }

        function open(): void {
            popup.open();
        }

        function close(): void {
            popup.close();
        }

        // Open with the keyboard cursor placed, for the SUPER+T submap
        // (hypr/submap-topbar.lua).
        function focus(): void {
            if (root.available)
                popup.openWithCursor();
        }
    }
}
