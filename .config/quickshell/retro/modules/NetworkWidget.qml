pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Networking
import "../ui" as Ui
import ".."

// Wifi and VPN.
//
// Wifi runs entirely on Quickshell.Networking. VPN cannot: that module models
// only wifi and wired devices, so WireGuard goes through nmcli in the Vpn
// singleton. Omarchy's equivalent panel is ~2000 lines because it also does band
// pinning, DNS switching, QR sharing and speed tests through a pile of omarchy-*
// scripts, and has no VPN support at all.
Item {
    id: root

    required property var barScreen
    required property bool primary

    readonly property var device: {
        var devices = Networking.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        }
        return null;
    }

    readonly property var networks: root.device ? root.device.networks.values : []

    readonly property var active: {
        for (var i = 0; i < root.networks.length; i++) {
            if (root.networks[i].connected)
                return root.networks[i];
        }
        return null;
    }

    readonly property bool available: Modules.allow("network", root.device !== null)

    // The network awaiting a passphrase, if any.
    property var pending: null

    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 0
    visible: root.available

    function strengthOf(network) {
        // NetworkManager reports 0-100; guard in case a backend uses 0-1.
        var raw = network.signalStrength;
        return raw <= 1 ? raw * 100 : raw;
    }

    function glyphFor(network) {
        if (!Networking.wifiEnabled)
            return "wifi_off";
        if (!network)
            return "signal_wifi_0_bar";
        var s = root.strengthOf(network);
        if (s >= 75)
            return "signal_wifi_4_bar";
        if (s >= 50)
            return "network_wifi_3_bar";
        if (s >= 25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    function needsPassphrase(network) {
        return !(network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe);
    }

    // Connected first, then remembered, then strongest signal first.
    //
    // The name tiebreak matters: equal signals previously compared as 0, and a
    // sort is only as stable as its input — the order coming out of
    // device.networks.values is not fixed, so equally-strong networks could
    // trade places between scans for no reason. Signal itself is compared
    // exactly; it is the actual ranking and rounding it would misorder
    // networks that genuinely differ.
    readonly property var sorted: {
        var list = root.networks.slice();
        list.sort(function (a, b) {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            var signal = root.strengthOf(b) - root.strengthOf(a);
            if (signal !== 0)
                return signal;
            return String(a.name).localeCompare(String(b.name));
        });
        return list;
    }

    function activate(network) {
        if (network.connected) {
            network.disconnect();
            return;
        }
        if (network.known || !root.needsPassphrase(network)) {
            network.connect();
            return;
        }
        root.pending = network;
    }

    Ui.Chip {
        id: chip

        width: root.width
        height: root.height
        interactive: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                Networking.wifiEnabled = !Networking.wifiEnabled;
            else
                popup.toggle();
        }

        Ui.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyphFor(root.active)
        }
    }

    Ui.Popup {
        id: popup

        anchorItem: chip
        barScreen: root.barScreen
        cardWidth: 360

        // Scanning is expensive and pointless while nobody is looking.
        onOpenedChanged: {
            if (root.device)
                root.device.scannerEnabled = popup.opened;
            if (!popup.opened)
                root.pending = null;
            Vpn.watching = popup.opened;
            Addresses.watching = popup.opened;
        }

        // First, above the wifi list. That list scrolls and is routinely long
        // enough to bury anything below it; the VPN section is short and fixed,
        // so putting it here keeps it reachable without scrolling.
        Ui.SectionLabel {
            text: "VPN"
        }

        Repeater {
            model: Vpn.connections

            Ui.PopupRow {
                required property var modelData

                readonly property bool pending: Vpn.pendingUuid === modelData.uuid

                rowKey: "vpn:" + modelData.uuid
                cursorKey: popup.cursorKey
                onCursorEntered: popup.cursorKey = "vpn:" + modelData.uuid

                glyph: modelData.active ? "vpn_key" : "vpn_key_off"
                text: modelData.name
                selected: modelData.active
                busy: pending
                onClicked: Vpn.toggle(modelData)
            }
        }

        Ui.PopupRow {
            // Explains itself rather than showing an empty gap on a machine
            // where the .conf has not been imported yet.
            visible: Vpn.connections.length === 0
            interactive: false
            text: "No WireGuard profiles"
            detail: "import with nmcli"
        }

        Ui.PopupRow {
            visible: Vpn.error !== ""
            interactive: false
            text: Vpn.error
        }

        // Between VPN and Wi-Fi because it belongs to both: the uplink's
        // address sits next to the tunnel's whenever the VPN is up. Rows are
        // readouts, listed with the default route first; a click or Enter
        // copies the bare address.
        Ui.SectionLabel {
            text: "IP"
        }

        Repeater {
            model: Addresses.entries

            Ui.PopupRow {
                required property var modelData

                readonly property string key: "ip:" + modelData.name + ":" + modelData.address

                rowKey: key
                cursorKey: popup.cursorKey
                onCursorEntered: popup.cursorKey = key

                glyph: {
                    if (modelData.isTunnel)
                        return "vpn_key";
                    return modelData.name.indexOf("wl") === 0 ? "wifi" : "lan";
                }
                text: modelData.name
                // The address gives way to "copied" for a beat after a click;
                // an underline would read as "in progress" like the VPN rows.
                detail: Addresses.copied === modelData.address ? "copied" : modelData.address
                onClicked: Addresses.copy(modelData.address)
            }
        }

        Ui.PopupRow {
            visible: Addresses.entries.length === 0
            interactive: false
            text: "No addresses"
        }

        Ui.PopupRow {
            readonly property var info: Addresses.publicInfo

            rowKey: "ip:public"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "ip:public"

            glyph: "public"
            text: "public"
            detail: {
                if (info)
                    return Addresses.copied === info.ip ? "copied" : info.ip;
                return Addresses.publicPending ? "…" : "unavailable";
            }
            interactive: info !== null
            onClicked: Addresses.copy(info.ip)
        }

        // The radio toggle belongs to the wifi group, so it has to sit *under*
        // the Wi-Fi header. Left above it, between the VPN rows and the rule, it
        // read as the last item of the VPN section.
        Ui.SectionLabel {
            text: "Wi-Fi"
        }

        Ui.PopupToggle {
            rowKey: "wifi-enabled"
            cursorKey: popup.cursorKey
            onCursorEntered: popup.cursorKey = "wifi-enabled"

            text: "Enabled"
            checked: Networking.wifiEnabled
            onToggled: (value) => Networking.wifiEnabled = value
        }

        Repeater {
            model: Networking.wifiEnabled ? root.sorted : []

            Column {
                id: entry

                required property var modelData

                width: parent.width
                spacing: 4

                Ui.PopupRow {
                    rowKey: "wifi:" + entry.modelData.name
                    cursorKey: popup.cursorKey
                    onCursorEntered: popup.cursorKey = "wifi:" + entry.modelData.name

                    glyph: root.glyphFor(entry.modelData)
                    text: entry.modelData.name !== "" ? entry.modelData.name : "(hidden)"
                    detail: Math.round(root.strengthOf(entry.modelData)) + "%"
                    trailingGlyph: root.needsPassphrase(entry.modelData) ? "lock" : ""
                    selected: entry.modelData.connected
                    busy: entry.modelData.stateChanging
                    onClicked: {
                        root.activate(entry.modelData);
                        // Enter on a row whose field is already showing (after
                        // an Escape back to the list) puts the caret back.
                        if (root.pending === entry.modelData)
                            passField.take();
                    }
                    // Right-click forgets, which is also how you recover from a
                    // saved-but-wrong passphrase.
                    onRightClicked: {
                        if (entry.modelData.known)
                            entry.modelData.forget();
                    }
                }

                Ui.PopupField {
                    id: passField

                    visible: root.pending === entry.modelData
                    placeholder: "Passphrase"
                    // Hiding hands the keyboard back to the list, or the popup
                    // would go deaf after a passphrase is submitted.
                    onVisibleChanged: {
                        if (visible)
                            take();
                        else
                            popup.reclaimFocus();
                    }
                    onAccepted: (value) => {
                        entry.modelData.connectWithPsk(value);
                        root.pending = null;
                    }
                }
            }
        }
    }

    IpcHandler {
        // Bars are instantiated per screen; only the primary one
        // claims the target, or a second monitor collides with it.
        target: "network"
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

        // Toggle a WireGuard profile by a case-insensitive substring of its
        // name, so it can take a keybind without opening the popup.
        function vpn(match: string): string {
            var needle = String(match || "").toLowerCase();
            for (var i = 0; i < Vpn.connections.length; i++) {
                var conn = Vpn.connections[i];
                if (needle === "" || conn.name.toLowerCase().indexOf(needle) !== -1) {
                    Vpn.toggle(conn);
                    return (conn.active ? "bringing down " : "bringing up ") + conn.name;
                }
            }
            return "no wireguard profile matching " + match;
        }

        function vpnStatus(): string {
            if (Vpn.connections.length === 0)
                return "no wireguard profiles";
            var out = [];
            for (var i = 0; i < Vpn.connections.length; i++)
                out.push(Vpn.connections[i].name + "=" + (Vpn.connections[i].active ? "up" : "down"));
            return out.join(" ");
        }
    }
}
