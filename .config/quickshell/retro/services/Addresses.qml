pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The machine's IP addresses, per interface, for the network popup.
//
// Quickshell's Networking module exposes devices but not their addresses, so
// this shells out to iproute2's JSON output: `ip -j addr` for the addresses
// and `ip -j route show default` for which interface carries the uplink.
// A WireGuard interface lists its tunnel address here whenever the VPN is up,
// which is the reason to show addresses at all rather than just the one.
Singleton {
    id: root

    // { name, address, prefix, isDefault, isTunnel }, one per global IPv4
    // address, the default route's interface first and the rest in interface
    // order. IPv6 is left out: temporary addresses multiply and none of them
    // is what you paste into a config.
    property var entries: []
    property string defaultDevice: ""

    // Set by the popup while it is on screen; nothing polls otherwise.
    property bool watching: false

    // The address most recently copied, cleared shortly after, so the row can
    // acknowledge the click.
    property string copied: ""

    // What the outside world sees: { ip, city, org } from ipinfo.io, or null
    // while unknown. This is a request to a third party, so it is made once
    // per popup opening and again when the VPN flips, never on the timer.
    property var publicInfo: null
    property bool publicPending: false

    property var raw: []

    function refresh() {
        if (!addrs.running)
            addrs.running = true;
        if (!routes.running)
            routes.running = true;
    }

    function refreshPublic() {
        if (fetcher.running)
            return;
        root.publicPending = true;
        fetcher.running = true;
    }

    // wl-copy forks a child that stays alive to serve pastes, so it must not
    // be a managed Process: that would tear the child down when the parent
    // exits and the clipboard would go empty again.
    function copy(address) {
        Quickshell.execDetached(["wl-copy", "--", address]);
        root.copied = address;
        copiedReset.restart();
    }

    function rebuild() {
        var out = [];
        for (var i = 0; i < root.raw.length; i++) {
            var iface = root.raw[i];
            if (iface.ifname === "lo" || !iface.addr_info)
                continue;
            for (var j = 0; j < iface.addr_info.length; j++) {
                var info = iface.addr_info[j];
                if (info.family !== "inet" || info.scope !== "global")
                    continue;
                out.push({
                    name: iface.ifname,
                    address: info.local,
                    prefix: info.prefixlen,
                    isDefault: iface.ifname === root.defaultDevice,
                    // WireGuard and tun devices have no link-layer type.
                    isTunnel: iface.link_type === "none"
                });
            }
        }
        out.sort(function (a, b) {
            return (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0);
        });
        root.entries = out;
    }

    onWatchingChanged: {
        if (root.watching) {
            root.refresh();
            root.refreshPublic();
        }
    }

    // The exit address is the point of showing it, so follow the tunnel.
    Connections {
        target: Vpn

        function onAnyActiveChanged() {
            if (root.watching)
                root.refreshPublic();
        }
    }

    Timer {
        running: root.watching
        interval: 3000
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: copiedReset

        interval: 900
        onTriggered: root.copied = ""
    }

    Process {
        id: addrs

        command: ["ip", "-j", "addr", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.raw = JSON.parse(text);
                } catch (e) {
                    root.raw = [];
                }
                root.rebuild();
            }
        }
    }

    Process {
        id: routes

        command: ["ip", "-j", "route", "show", "default"]

        stdout: StdioCollector {
            onStreamFinished: {
                var dev = "";
                try {
                    var list = JSON.parse(text);
                    // Lowest metric wins, which is the one the kernel uses.
                    var best = null;
                    for (var i = 0; i < list.length; i++) {
                        if (best === null || (list[i].metric || 0) < (best.metric || 0))
                            best = list[i];
                    }
                    if (best)
                        dev = best.dev || "";
                } catch (e) {
                }
                root.defaultDevice = dev;
                root.rebuild();
            }
        }
    }

    Process {
        id: fetcher

        command: ["curl", "-s", "--max-time", "4", "https://ipinfo.io/json"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var info = JSON.parse(text);
                    root.publicInfo = info.ip ? {
                        ip: info.ip,
                        city: info.city || "",
                        org: info.org || ""
                    } : null;
                } catch (e) {
                    root.publicInfo = null;
                }
                root.publicPending = false;
            }
        }
    }

}
