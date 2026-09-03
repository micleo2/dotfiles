pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "rules.js" as Rules
import "../lcd/text.js" as TextUtil
import ".."

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
//
// Nothing here reads a notification's text directly. Each one is turned into
// a plain view and run through rules.js first, which is where
// a noisy sender gets rewritten, muted or dropped; the view is kept on the
// lifetime entry and rebuilt whenever the sender updates its text.
Singleton {
    id: root

    // Live toasts, newest first. Rendered by Toasts.qml.
    property var popups: []

    // Unread toasts as plain snapshots, newest first, capped: ones that
    // expired unseen, and ones silenced by do-not-disturb. Anything dismissed
    // by hand counts as read and never lands here. Mirrored to history.json beside settings.json so a
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
    readonly property int maxDuration: 10000

    // One entry per live toast: { notification, view, arrived, duration,
    // deadline, paused }. Keyed by object identity rather than notification
    // id, because ids restart from 1 each server generation and keepOnReload
    // carries the old generation over. Replaced wholesale on change so
    // bindings notice.
    property var lifetimes: []
    // Ticks while anything is on screen; the countdown bars bind to it.
    property double now: Date.now()

    // The processed view of a notification: what the rules made of it.
    function buildView(notification) {
        return Rules.process({
            appName: String(notification.appName || ""),
            desktopEntry: String(notification.desktopEntry || ""),
            summary: TextUtil.plain(notification.summary),
            body: TextUtil.plain(notification.body),
            urgency: notification.urgency,
            expireTimeout: notification.expireTimeout,
            transient: notification.transient === true
        });
    }

    readonly property var blankView: ({
            appName: "",
            desktopEntry: "",
            summary: "",
            body: "",
            urgency: NotificationUrgency.Normal,
            expireTimeout: -1,
            transient: false
        })

    // The view kept on the live entry. A toast being torn down can still
    // evaluate this after its entry is gone, so that case reads blank rather
    // than touching a notification the server may have destroyed.
    function viewOf(notification) {
        var entry = root.entryFor(notification);
        return entry ? entry.view : root.blankView;
    }

    function durationFor(view) {
        if (view.duration !== undefined)
            return Math.max(0, view.duration);
        if (view.urgency === NotificationUrgency.Critical)
            return 0;
        var floor = view.urgency === NotificationUrgency.Low ? root.lowDuration : root.normalDuration;
        // expireTimeout is milliseconds; -1 asks for the server default and
        // 0 is treated the same way, as omarchy does, rather than as "forever".
        var asked = view.expireTimeout > 0 ? view.expireTimeout : 0;
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

    // Milliseconds this toast lives, 0 for one that never expires.
    function duration(notification) {
        var entry = root.entryFor(notification);
        return entry ? entry.duration : 0;
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
    // new text deserves a full look, and a fresh pass through the rules.
    function arm(notification) {
        root.now = Date.now();
        var view = root.buildView(notification);
        var duration = root.durationFor(view);
        var next = [];
        var found = false;
        for (var i = 0; i < root.lifetimes.length; i++) {
            var entry = root.lifetimes[i];
            if (entry.notification === notification) {
                found = true;
                next.push({
                    notification: notification,
                    view: view,
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
                view: view,
                arrived: root.now,
                duration: duration,
                deadline: root.now + duration,
                paused: false
            });
        root.lifetimes = next;
        return view;
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

    // -------------------------------------------------------------- history

    // A plain copy of the view for the history list, taken before the server
    // destroys the object.
    function snapshot(notification, reason) {
        var arrived = root.arrivedAt(notification);
        var view = root.viewOf(notification);
        return {
            key: arrived + ":" + notification.id,
            appName: view.appName,
            summary: view.summary,
            body: view.body,
            urgency: view.urgency,
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

    // Dismissed toasts count as read and never reach history, so the order
    // here only keeps the log readable.
    function reset() {
        root.dismissAll();
        root.clearHistory();
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

        var view = root.arm(notification);

        // Dropped by a rule: gone as if it never arrived.
        if (view.drop === true) {
            root.drop(notification);
            notification.dismiss();
            return;
        }

        // Silenced, by do-not-disturb or by a rule: straight to history.
        // The transient hint means not worth looking back at, so not even
        // there.
        if (view.silent === true || (root.doNotDisturb && view.bypassDnd !== true)) {
            if (!view.transient)
                root.record(root.snapshot(notification, "silenced"));
            root.drop(notification);
            notification.dismiss();
            return;
        }

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

    // Only a dismiss — a click here, or a dismiss keybind — means a toast was
    // read, because those are the only paths that produce that reason. One
    // that ran out went to the inbox unseen.
    function unread(reason) {
        return reason !== NotificationCloseReason.Dismissed;
    }

    // A sender withdrawing its own notification does not take it off the
    // screen. Chromium web apps (Google Messages) send CloseNotification about
    // seven seconds in, before the toast's own life is up, which from this
    // side looks like it vanished unread. The server destroys the object on
    // close, so the toast carries on from a plain copy that keeps the same
    // countdown, expires into the inbox, and still dismisses and focuses the
    // app on click; only its actions are gone with the sender.
    function withdraw(notification) {
        var ghost = {
            withdrawn: true,
            id: notification.id,
            appName: String(notification.appName || ""),
            desktopEntry: String(notification.desktopEntry || ""),
            summary: String(notification.summary || ""),
            body: String(notification.body || ""),
            urgency: notification.urgency,
            expireTimeout: notification.expireTimeout,
            transient: notification.transient,
            actions: []
        };
        ghost.dismiss = function () {
            root.forget(ghost, NotificationCloseReason.Dismissed);
        };
        ghost.expire = function () {
            root.forget(ghost, NotificationCloseReason.Expired);
        };
        root.popups = root.popups.map(function (n) {
            return n === notification ? ghost : n;
        });
        root.lifetimes = root.lifetimes.map(function (entry) {
            if (entry.notification !== notification)
                return entry;
            return {
                notification: ghost,
                view: entry.view,
                arrived: entry.arrived,
                duration: entry.duration,
                deadline: entry.deadline,
                paused: entry.paused
            };
        });
    }

    function forget(notification, reason) {
        var entry = root.entryFor(notification);
        var elapsed = entry ? Math.round((Date.now() - entry.arrived) / 100) / 10 : -1;
        console.info("notification closed: app=" + notification.appName + " entry=" + notification.desktopEntry + " reason=" + NotificationCloseReason.toString(reason) + " after=" + elapsed + "s transient=" + notification.transient + " timeout=" + notification.expireTimeout);
        if (reason === NotificationCloseReason.CloseRequested && root.popups.indexOf(notification) >= 0) {
            root.withdraw(notification);
            return;
        }
        if (root.unread(reason) && !root.viewOf(notification).transient)
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
        // A rule may name the window outright; otherwise the sender's own
        // names, which are the raw ones, since a rule's header rewrite (a
        // site name) is not a window.
        var wanted = [root.viewOf(notification).appId, notification.desktopEntry, notification.appName].map(function (s) {
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

        function reset(): void {
            root.reset();
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
