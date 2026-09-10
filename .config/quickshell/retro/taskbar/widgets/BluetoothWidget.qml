pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../ui" as Ui
import "../.."
import "../../services"

Ui.Chip {
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

    // The device whose pairing is in flight. A fresh pair is not trusted, so
    // BlueZ would refuse its reconnects; trusting and connecting once paired
    // makes one click do what bluetoothctl's pair/trust/connect does.
    property var pairingTarget: null

    function activate(device) {
        if (device.connected) {
            device.disconnect();
            return;
        }
        if (device.paired || device.bonded) {
            device.connect();
            return;
        }
        root.pairingTarget = device;
        device.pair();
    }

    function settlePairing() {
        var device = root.pairingTarget;
        if (!device)
            return;
        if (device.paired) {
            root.pairingTarget = null;
            device.trusted = true;
            device.connect();
        } else if (!device.pairing) {
            root.pairingTarget = null;
        }
    }

    Connections {
        target: root.pairingTarget

        function onPairedChanged() {
            root.settlePairing();
        }

        // Paired may still be landing when the pair call returns, so the
        // verdict is read a turn later.
        function onPairingChanged() {
            Qt.callLater(root.settlePairing);
        }
    }

    // Powered is not persistent: BlueZ's AutoEnable powers every adapter back
    // up at boot. An rfkill soft block is restored by systemd-rfkill, so it is
    // the block that makes "off" stick, and the unblock that lets "on" work.
    function setPower(value) {
        if (!root.adapter)
            return;
        if (value) {
            Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
            root.adapter.enabled = true;
            rfkillGuard.restart();
        } else {
            root.adapter.enabled = false;
            Quickshell.execDetached(["rfkill", "block", "bluetooth"]);
        }
    }

    Timer {
        id: rfkillGuard

        // The unblock and the power-on race; a set that landed while still
        // blocked fails silently, so it is repeated once the block is gone.
        interval: 1500
        onTriggered: {
            if (root.adapter && !root.adapter.enabled)
                root.adapter.enabled = true;
        }
    }

    interactive: true

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton)
            root.setPower(!(root.adapter && root.adapter.enabled));
        else
            popup.toggle();
    }

    Ui.Glyph {
        anchors.verticalCenter: parent.verticalCenter
        slot: Config.settings.bar.iconSlot
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

    Ui.Popup {
        id: popup

        anchorItem: root
        barScreen: root.barScreen

        // Discovery burns power and floods the list; only scan while visible.
        // Switched a beat after the popup rather than in the click, so the
        // popup and the released chip paint before the list churns.
        onOpenedChanged: discoverySwitch.restart()

        Timer {
            id: discoverySwitch

            interval: 50
            onTriggered: {
                if (root.adapter && root.adapter.enabled)
                    root.adapter.discovering = popup.opened;
            }
        }

        Ui.PopupToggle {
            rowKey: "power"

            text: "Bluetooth"
            checked: root.adapter ? root.adapter.enabled : false
            onToggled: (value) => root.setPower(value)
        }

        Ui.PopupToggle {
            rowKey: "scan"

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
            // Diffed by identity: `sorted` re-evaluates on every BlueZ
            // property update, of which there are many per second during a
            // scan, and a Repeater handed a fresh array each time destroys
            // and rebuilds every delegate for nothing. With the diff, only a
            // device that actually appeared gets a row built.
            model: ScriptModel {
                values: root.sorted
            }

            Ui.PopupRow {
                required property var modelData

                rowKey: modelData.address

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

    Ui.PopupIpc {
        target: "bluetooth"
        enabled: root.primary
    }
}
