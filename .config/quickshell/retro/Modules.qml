pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which bar modules run on this host.
//
// modules.json is tracked in the dotfiles repo and describes every machine, so
// bringing up a new host is a commit rather than a hand-made local file.
// Per module:
//
//   "auto"   show only on a laptop, and only if the hardware is present
//   true     show wherever the hardware is present
//   false    never show
//
// The hardware predicate applies even to an explicit `true`, so opting a module
// in on a machine that cannot support it is a no-op rather than a broken widget.
Singleton {
    id: root

    property var defaults: ({})
    property var hosts: ({})
    property string hostname: ""

    function setting(id) {
        var host = root.hosts[root.hostname];
        if (host && host[id] !== undefined)
            return host[id];
        if (root.defaults[id] !== undefined)
            return root.defaults[id];
        return "auto";
    }

    function allow(id, hardware) {
        if (!hardware)
            return false;
        var value = root.setting(id);
        if (value === false)
            return false;
        if (value === true)
            return true;
        return Host.isLaptop;
    }

    FileView {
        path: Quickshell.shellPath("modules.json")
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            try {
                var parsed = JSON.parse(text());
                root.defaults = parsed.defaults || {};
                root.hosts = parsed.hosts || {};
            } catch (e) {
                console.warn("retro: modules.json is not valid JSON; every module falls back to \"auto\":", e);
                root.defaults = {};
                root.hosts = {};
            }
        }
    }

    FileView {
        // Quickshell has no hostname API and HOSTNAME is unset under uwsm.
        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }
}
