pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import "../../ui" as Ui
import "../.."
import "../../services"

// Wifi, ethernet and VPN.
//
// Wifi runs entirely on Quickshell.Networking. VPN cannot: that module models
// only wifi and wired devices, so WireGuard goes through nmcli in the Vpn
// singleton. Omarchy's equivalent panel is ~2000 lines because it also does band
// pinning, DNS switching, QR sharing and speed tests through a pile of omarchy-*
// scripts, and has no VPN support at all.
Ui.Chip {
    id: root

    required property var barScreen
    required property bool primary

    function findDevice(type) {
        var devices = Networking.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].type === type)
                return devices[i];
        }
        return null;
    }

    readonly property var wifiDevice: root.findDevice(DeviceType.Wifi)
    readonly property var wiredDevice: root.findDevice(DeviceType.Wired)
    // Without NetworkManager there are no devices to ask, so the default
    // route stands in for "cable in".
    readonly property bool nmBacked: Networking.backend === NetworkBackendType.NetworkManager
    readonly property bool wired: root.wiredDevice !== null ? root.wiredDevice.connected : Addresses.defaultDevice !== ""

    readonly property var networks: root.wifiDevice ? root.wifiDevice.networks.values : []

    readonly property var active: {
        for (var i = 0; i < root.networks.length; i++) {
            if (root.networks[i].connected)
                return root.networks[i];
        }
        return null;
    }

    // A wired-only machine still gets the VPN and IP sections; one without
    // NetworkManager gets the IP section and a link glyph.
    readonly property bool available: Modules.allow("network", !root.nmBacked || root.wifiDevice !== null || root.wiredDevice !== null)

    // NetworkManager's own HTTP probe, when it is configured to run one
    // (/etc/NetworkManager/conf.d, `connectivity.uri`). Portal means the probe
    // was answered by something other than its check page.
    readonly property bool connectivityKnown: Networking.canCheckConnectivity && Networking.connectivityCheckEnabled
    readonly property bool portal: root.connectivityKnown && Networking.connectivity === NetworkConnectivity.Portal
    readonly property bool limited: root.connectivityKnown && Networking.connectivity === NetworkConnectivity.Limited

    // Kept asking while sign-in is needed; the browser is usually up and the
    // popup closed by the time the portal lets the probe through.
    Timer {
        interval: 10000
        repeat: true
        running: root.portal || root.limited
        onTriggered: Networking.checkConnectivity()
    }

    function openPortal() {
        // A fixed plain-http URL so the portal's redirect does the work; the
        // portal's own address is never trusted.
        Quickshell.execDetached(["xdg-open", "http://ping.archlinux.org/nm-check.txt"]);
    }

    // The network awaiting a passphrase, if any.
    property var pending: null

    // The network the user last asked to connect, watched for the outcome.
    // Kept on the widget rather than in a row: rows come and go with the
    // list, and NetworkManager reports a failure seconds after the click.
    property var attempted: null

    // The network whose last attempt failed, and why. NetworkManager keeps
    // the profile it created for a wrong passphrase, so the network turns
    // `known` and a plain connect() would retry the bad key forever with no
    // word to the user. This is what makes the next click ask again.
    property var failed: null
    property int failReason: ConnectionFailReason.Unknown

    visible: root.available

    function strengthOf(network) {
        // NetworkManager reports 0-100; guard in case a backend uses 0-1.
        var raw = network.signalStrength;
        return raw <= 1 ? raw * 100 : raw;
    }

    function chipGlyph() {
        if (root.portal)
            return "captive_portal";
        if (root.active)
            return root.glyphFor(root.active);
        if (root.wired || !root.wifiDevice)
            return "lan";
        return root.glyphFor(null);
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

    // The saved network whose forget is awaiting its second click, or null.
    // Forgetting drops the passphrase, so one stray right-click must not do
    // it: the first asks, the second (on the same row) does.
    property var forgetting: null

    function forget(network) {
        if (!network.known)
            return;
        if (root.forgetting === network) {
            root.forgetting = null;
            network.forget();
        } else {
            root.forgetting = network;
        }
    }

    // The network under the field can vanish from the scan; its object dies
    // with it, so the field and the pending forget have to go too.
    onSortedChanged: {
        if (root.pending !== null && root.sorted.indexOf(root.pending) === -1)
            root.pending = null;
        if (root.forgetting !== null && root.sorted.indexOf(root.forgetting) === -1)
            root.forgetting = null;
    }

    function failureText(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "wrong passphrase";
        case ConnectionFailReason.WifiClientDisconnected:
        case ConnectionFailReason.WifiClientFailed:
        case ConnectionFailReason.WifiAuthTimeout:
            return "auth failed";
        case ConnectionFailReason.WifiNetworkLost:
            return "network lost";
        default:
            return "failed";
        }
    }

    function attempt(network) {
        root.attempted = network;
        if (root.failed === network)
            root.failed = null;
    }

    // The list is shown in two sections, saved networks then the rest. The
    // sort already puts saved first; the split only makes that visible, so
    // with dozens in range the saved handful is not hunted for.
    function slice(known) {
        var out = [];
        for (var i = 0; i < root.sorted.length; i++) {
            if (root.sorted[i].known === known)
                out.push(root.sorted[i]);
        }
        return out;
    }

    readonly property var saved: Networking.wifiEnabled ? root.slice(true) : []
    readonly property var nearby: Networking.wifiEnabled ? root.slice(false) : []

    function activate(network) {
        if (network.connected) {
            network.disconnect();
            return;
        }
        // A failed network is asked for its passphrase again even though it
        // is `known`: connectWithPsk overwrites the saved key, so this is the
        // retry. Forgetting first is not needed.
        var askAgain = root.failed === network;
        if (root.needsPassphrase(network) && (!network.known || askAgain)) {
            root.pending = network;
            return;
        }
        root.attempt(network);
        network.connect();
    }

    Connections {
        target: root.attempted

        function onConnectionFailed(reason) {
            root.failed = root.attempted;
            root.failReason = reason;
        }
    }

    // The failure label is stale once the network is up, whoever connected it.
    Connections {
        target: root.failed

        function onConnectedChanged() {
            if (root.failed.connected)
                root.failed = null;
        }
    }

    Connections {
        target: Networking

        function onWifiEnabledChanged() {
            // The rows are gone with the radio, and the field with them.
            if (!Networking.wifiEnabled)
                root.pending = null;
        }
    }

    interactive: true

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            if (root.wifiDevice)
                Networking.wifiEnabled = !Networking.wifiEnabled;
        } else {
            popup.toggle();
        }
    }

    Ui.Glyph {
        anchors.verticalCenter: parent.verticalCenter
        // A cable out with no wifi to fall back on is the wired counterpart of
        // the radio being off.
        opacity: !root.wifiDevice && !root.wired ? 0.5 : 1
        text: root.chipGlyph()
    }

    Ui.Popup {
        id: popup

        anchorItem: root
        barScreen: root.barScreen
        cardWidth: 360

        // Scanning is expensive and pointless while nobody is looking. The
        // scanner is switched a beat after the popup, not in the click: the
        // switch makes every unsaved network appear at once, and building
        // those rows is better spent after the popup and the released chip
        // have painted.
        onOpenedChanged: {
            scanSwitch.restart();
            if (!popup.opened) {
                root.pending = null;
                root.forgetting = null;
            }
            Vpn.watching = popup.opened;
            Addresses.watching = popup.opened;
        }

        Timer {
            id: scanSwitch

            interval: 50
            onTriggered: {
                if (root.wifiDevice)
                    root.wifiDevice.scannerEnabled = popup.opened;
            }
        }

        Ui.PopupRow {
            visible: root.portal
            rowKey: "portal"

            glyph: "captive_portal"
            text: "Captive portal"
            detail: "sign in"
            onClicked: root.openPortal()
        }

        Ui.PopupRow {
            visible: root.limited && !root.portal
            interactive: false
            glyph: "link_off"
            text: "No internet"
        }

        // First, above the wifi list. That list scrolls and is routinely long
        // enough to bury anything below it; the VPN section is short and fixed,
        // so putting it here keeps it reachable without scrolling.
        Ui.SectionLabel {
            visible: Vpn.available
            text: "VPN"
        }

        Repeater {
            model: Vpn.connections

            Ui.PopupRow {
                required property var modelData

                readonly property bool pending: Vpn.pendingUuid === modelData.uuid

                rowKey: "vpn:" + modelData.uuid

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
            visible: Vpn.available && Vpn.connections.length === 0
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

        Ui.SectionLabel {
            visible: root.wiredDevice !== null
            text: "Ethernet"
        }

        Ui.PopupRow {
            visible: root.wiredDevice !== null
            interactive: false
            glyph: "lan"
            text: root.wiredDevice ? root.wiredDevice.name : ""
            detail: {
                if (!root.wiredDevice)
                    return "";
                if (root.wired)
                    return root.wiredDevice.linkSpeed > 0 ? root.wiredDevice.linkSpeed + " Mb/s" : "connected";
                return ConnectionState.toString(root.wiredDevice.state).toLowerCase();
            }
        }

        // The radio toggle belongs to the wifi group, so it has to sit *under*
        // the Wi-Fi header. Left above it, between the VPN rows and the rule, it
        // read as the last item of the VPN section. Both go with the radio:
        // a wired-only machine has no Wi-Fi section at all.
        Ui.SectionLabel {
            visible: root.wifiDevice !== null
            text: "Wi-Fi"
        }

        Ui.PopupToggle {
            visible: root.wifiDevice !== null
            rowKey: "wifi-enabled"

            text: "Enabled"
            checked: Networking.wifiEnabled
            onToggled: (value) => Networking.wifiEnabled = value
        }

        // The headers hide with their rows: the "Wi-Fi" header and the toggle
        // above are all there is to see while the radio is off.
        Ui.SectionLabel {
            visible: root.saved.length > 0
            sub: true
            text: "Saved"
        }

        Repeater {
            // Diffed by identity rather than fed the array: `sorted` is fresh
            // on every scan tick, since it reads each network's signal, and a
            // Repeater handed a fresh array destroys and recreates every row.
            // That tore down the passphrase field, text and all, every few
            // seconds. With the diff, a reorder moves rows and only a network
            // that actually appeared gets a new one.
            model: ScriptModel {
                values: root.saved
            }
            delegate: networkRow
        }

        Ui.SectionLabel {
            visible: root.nearby.length > 0
            sub: true
            text: "Nearby"
        }

        Repeater {
            model: ScriptModel {
                values: root.nearby
            }
            delegate: networkRow
        }

        Component {
            id: networkRow

            Column {
                id: entry

                required property var modelData

                width: parent.width
                spacing: 4

                Ui.PopupRow {
                    id: row

                    rowKey: "wifi:" + entry.modelData.name

                    readonly property bool asking: root.forgetting === entry.modelData

                    glyph: root.glyphFor(entry.modelData)
                    text: entry.modelData.name !== "" ? entry.modelData.name : "(hidden)"
                    // The signal readout gives way to the verdict of the last
                    // attempt, until the next one starts, and to the forget
                    // question while one is open.
                    detail: {
                        if (row.asking)
                            return "forget?";
                        if (root.failed === entry.modelData)
                            return root.failureText(root.failReason);
                        return Math.round(root.strengthOf(entry.modelData)) + "%";
                    }
                    trailingGlyph: root.needsPassphrase(entry.modelData) ? "lock" : ""
                    // Saved rows offer a forget button while pointed at. It
                    // turns into the confirming check once asked.
                    actionGlyph: {
                        if (!entry.modelData.known)
                            return "";
                        if (row.asking)
                            return "check";
                        return row.hasCursor ? "delete" : "";
                    }
                    actionColor: row.asking ? Config.colors.urgent : Config.colors.text
                    onActionClicked: root.forget(entry.modelData)
                    // Moving off the row withdraws the question.
                    onHasCursorChanged: {
                        if (!row.hasCursor && row.asking)
                            root.forgetting = null;
                    }
                    selected: entry.modelData.connected
                    busy: entry.modelData.stateChanging
                    onClicked: {
                        root.activate(entry.modelData);
                        // Enter on a row whose field is already showing (after
                        // an Escape back to the list) puts the caret back.
                        if (root.pending === entry.modelData)
                            passField.take();
                    }
                    // Right-click and Delete take the same two steps as the
                    // button: ask, then forget.
                    onRightClicked: root.forget(entry.modelData)
                }

                Ui.PopupField {
                    id: passField

                    visible: root.pending === entry.modelData
                    placeholder: "Passphrase"
                    // Hiding hands the keyboard back to the list, or the popup
                    // would go deaf after a passphrase is submitted.
                    onVisibleChanged: {
                        if (visible) {
                            // Never a rejected passphrase from last time.
                            text = "";
                            take();
                        } else {
                            popup.reclaimFocus();
                        }
                    }
                    onAccepted: (value) => {
                        if (value === "")
                            return;
                        root.attempt(entry.modelData);
                        entry.modelData.connectWithPsk(value);
                        root.pending = null;
                    }
                }
            }
        }
    }

    Ui.PopupIpc {
        target: "network"
        enabled: root.primary

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
