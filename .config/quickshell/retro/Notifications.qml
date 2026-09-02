pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// The notification daemon. The server below claims
// org.freedesktop.Notifications on the session bus, so anything speaking the
// freedesktop protocol (notify-send, libnotify apps, Chromium web apps) lands
// here and nowhere else — swaync is no longer started.
//
// The shape follows omarchy's notification plugin with the persistence layer
// left out: live toasts are the Notification objects themselves, bound to
// directly. A replaces_id update rewrites the same object in place with no
// second signal, so the toasts pick up new text for free. keepOnReload keeps
// them across a config reload, which is the restart that actually happens.
Singleton {
    id: root

    // Live toasts, newest first. Rendered by notifications/Toasts.qml.
    property var popups: []

    // Closed toasts as plain snapshots, newest first, capped. Silenced
    // notifications are written here too: "what did I miss" is what a
    // history is for. Mirrored to history.json beside settings.json so a
    // config reload, which recreates this singleton, does not wipe it.
    readonly property var history: historyStore.entries
    readonly property int historyLimit: 30

    // The history popup of the primary bar, registered by NotificationWidget
    // so the IPC handler can open it.
    property var panel: null

    readonly property bool doNotDisturb: Settings.doNotDisturb

    function setDoNotDisturb(value) {
        Settings.doNotDisturb = value;
    }

    function toggleDoNotDisturb() {
        root.setDoNotDisturb(!root.doNotDisturb);
    }

    // Lifetimes. A toast lives at least this long by urgency, stretched up to
    // the cap if the sender asked for more; critical never expires on its own.
    readonly property int lowDuration: 5000
    readonly property int normalDuration: 8000
    readonly property int maxDuration: 30000

    // One entry per live toast: { notification, arrived, duration, deadline,
    // paused }. Keyed by object identity rather than notification id, because
    // ids restart from 1 each server generation and keepOnReload carries the
    // old generation over. Replaced wholesale on change so bindings notice.
    property var lifetimes: []
    // Ticks while anything is on screen; the countdown bars bind to it.
    property double now: Date.now()

    function durationFor(notification) {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        var floor = notification.urgency === NotificationUrgency.Low ? root.lowDuration : root.normalDuration;
        // expireTimeout is milliseconds; -1 asks for the server default and
        // 0 is treated the same way, as omarchy does, rather than as "forever".
        var asked = notification.expireTimeout > 0 ? notification.expireTimeout : 0;
        return Math.min(root.maxDuration, Math.max(floor, asked));
    }

    function entryFor(notification) {
        for (var i = 0; i < root.lifetimes.length; i++) {
            if (root.lifetimes[i].notification === notification)
                return root.lifetimes[i];
        }
        return null;
    }

    // 0..1 of the toast's life left; 1 for one that never expires.
    function remaining(notification) {
        var entry = root.entryFor(notification);
        if (!entry || entry.duration <= 0)
            return 1;
        return Math.max(0, Math.min(1, (entry.deadline - root.now) / entry.duration));
    }

    function expires(notification) {
        var entry = root.entryFor(notification);
        return entry !== null && entry.duration > 0;
    }

    function arrivedAt(notification) {
        var entry = root.entryFor(notification);
        return entry ? entry.arrived : Date.now();
    }

    // Start, or restart, the clock on a toast. Restarted on a content update:
    // new text deserves a full look.
    function arm(notification) {
        root.now = Date.now();
        var duration = root.durationFor(notification);
        var next = [];
        var found = false;
        for (var i = 0; i < root.lifetimes.length; i++) {
            var entry = root.lifetimes[i];
            if (entry.notification === notification) {
                found = true;
                next.push({
                    notification: notification,
                    arrived: entry.arrived,
                    duration: duration,
                    deadline: root.now + duration,
                    paused: entry.paused
                });
            } else {
                next.push(entry);
            }
        }
        if (!found)
            next.push({
                notification: notification,
                arrived: root.now,
                duration: duration,
                deadline: root.now + duration,
                paused: false
            });
        root.lifetimes = next;
    }

    // Hover holds the countdown; the deadline slides forward while paused.
    function setPaused(notification, paused) {
        var entry = root.entryFor(notification);
        if (!entry || entry.paused === paused)
            return;
        entry.paused = paused;
        root.lifetimes = root.lifetimes.slice();
    }

    function tick() {
        var t = Date.now();
        var dt = t - root.now;
        root.now = t;
        var expired = [];
        var slid = false;
        for (var i = 0; i < root.lifetimes.length; i++) {
            var entry = root.lifetimes[i];
            if (entry.duration <= 0)
                continue;
            if (entry.paused) {
                entry.deadline += dt;
                slid = true;
            } else if (entry.deadline <= t) {
                expired.push(entry.notification);
            }
        }
        if (slid)
            root.lifetimes = root.lifetimes.slice();
        for (var j = 0; j < expired.length; j++)
            expired[j].expire();
    }

    Timer {
        interval: 100
        repeat: true
        running: root.popups.length > 0
        onTriggered: root.tick()
    }

    // ---------------------------------------------------------------- rules

    // Two kinds punch through do-not-disturb, chosen to be rare and
    // intentional: critical alerts from the bare CLI. Critical alone is not
    // enough, because chat apps mark everything critical to force visibility.
    function bypassesDnd(notification) {
        return notification.urgency === NotificationUrgency.Critical && notification.appName === "notify-send";
    }

    // The freedesktop transient hint: not worth looking back at.
    function ephemeral(notification) {
        return notification.transient;
    }

    // A plain copy for the history list, taken before the server destroys
    // the object.
    function snapshot(notification, reason) {
        var arrived = root.arrivedAt(notification);
        return {
            key: arrived + ":" + notification.id,
            appName: String(notification.appName || ""),
            summary: String(notification.summary || ""),
            body: String(notification.body || ""),
            urgency: notification.urgency,
            arrived: arrived,
            time: Qt.formatTime(new Date(arrived), "HH:mm"),
            reason: reason
        };
    }

    function record(entry) {
        historyStore.entries = [entry].concat(root.history).slice(0, root.historyLimit);
    }

    function forgetHistory(index) {
        var next = root.history.slice();
        next.splice(index, 1);
        historyStore.entries = next;
    }

    function clearHistory() {
        historyStore.entries = [];
    }

    Process {
        // FileView will not create intermediate directories.
        running: true
        command: ["mkdir", "-p", Settings.stateDir]
        onExited: historyFile.reload() // qmllint disable signal-handler-parameters
    }

    FileView {
        id: historyFile

        path: Settings.stateDir + "/history.json"
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter { // qmllint disable unresolved-type
            id: historyStore

            property var entries: []
        }
    }

    // ------------------------------------------------------------- lifecycle

    function handle(notification) {
        // Untracked notifications are discarded by the server as soon as the
        // handler returns.
        notification.tracked = true;

        if (root.doNotDisturb && !root.bypassesDnd(notification)) {
            root.arm(notification);
            if (!root.ephemeral(notification))
                root.record(root.snapshot(notification, "silenced"));
            root.drop(notification);
            notification.dismiss();
            return;
        }

        root.arm(notification);
        notification.closed.connect(function (reason) {
            root.forget(notification, reason);
        });
        notification.summaryChanged.connect(function () {
            root.arm(notification);
        });
        notification.bodyChanged.connect(function () {
            root.arm(notification);
        });
        root.popups = [notification].concat(root.popups);
    }

    function drop(notification) {
        root.lifetimes = root.lifetimes.filter(function (entry) {
            return entry.notification !== notification;
        });
    }

    function forget(notification, reason) {
        if (!root.ephemeral(notification))
            root.record(root.snapshot(notification, reason));
        root.popups = root.popups.filter(function (n) {
            return n !== notification;
        });
        root.drop(notification);
    }

    function dismissAll() {
        var live = root.popups.slice();
        for (var i = 0; i < live.length; i++)
            live[i].dismiss();
    }

    // Left click: the sender's default action if it registered one, else
    // jump to its window. Chat apps rarely register an action and just
    // expect click-to-focus.
    function invoke(notification) {
        var invoked = false;
        var actions = notification.actions;
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default") {
                actions[i].invoke();
                invoked = true;
                break;
            }
        }
        if (!invoked)
            root.focusApp(notification);
        notification.dismiss();
    }

    function focusApp(notification) {
        var wanted = [notification.desktopEntry, notification.appName].map(function (s) {
            return String(s || "").toLowerCase();
        }).filter(function (s) {
            return s !== "";
        });
        if (wanted.length === 0)
            return;
        var levels = Hyprland.toplevels.values;
        for (var i = 0; i < levels.length; i++) {
            var level = levels[i];
            var wayland = level.wayland;
            if (wayland === null || wayland === undefined)
                continue;
            var appId = String(wayland.appId || "").toLowerCase();
            if (appId === "")
                continue;
            for (var j = 0; j < wanted.length; j++) {
                if (appId === wanted[j] || appId.indexOf(wanted[j]) >= 0 || wanted[j].indexOf(appId) >= 0) {
                    var address = String(level.address);
                    if (address.indexOf("0x") !== 0)
                        address = "0x" + address;
                    Hyprland.dispatch("focuswindow address:" + address);
                    return;
                }
            }
        }
    }

    NotificationServer {
        id: server

        keepOnReload: true
        imageSupported: false
        actionsSupported: true
        bodySupported: true
        // Plain text only: the toast is a character LCD, and a body that is
        // never parsed as markup cannot smuggle an <img> fetch either.
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        persistenceSupported: false

        onNotification: (notification) => root.handle(notification)
    }

    IpcHandler {
        target: "notifications"

        // `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
        // `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
        function dismissOne(): void {
            if (root.popups.length > 0)
                root.popups[0].dismiss();
        }

        function dismissAll(): void {
            root.dismissAll();
        }

        function invokeLast(): void {
            if (root.popups.length > 0)
                root.invoke(root.popups[0]);
        }

        function toggleDnd(): string {
            root.toggleDoNotDisturb();
            return root.doNotDisturb ? "on" : "off";
        }

        function dnd(value: string): string {
            root.setDoNotDisturb(value === "on" || value === "true" || value === "1");
            return root.doNotDisturb ? "on" : "off";
        }

        function status(): string {
            return "dnd=" + (root.doNotDisturb ? "on" : "off") + " live=" + root.popups.length + " history=" + root.history.length;
        }

        function clearHistory(): void {
            root.clearHistory();
        }

        // The bar's history popup; `focus` opens it with the keyboard cursor
        // placed, for the SUPER+T submap.
        function toggle(): void {
            if (root.panel)
                root.panel.toggle();
        }

        function focus(): void {
            if (root.panel)
                root.panel.openWithCursor();
        }
    }
}
