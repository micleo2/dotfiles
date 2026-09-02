.pragma library

// The notification pre-processor. Every notification is turned into a plain
// "view" and pushed through RULES, in order, before anything else looks at
// it. The toast, the history and the lifetime all read the view and never
// the raw notification, so a rule here rewrites what is shown, how long it
// stays and whether it appears at all.
//
// A view starts as a copy of the notification, text already stripped of
// markup and whitespace-collapsed (newlines kept):
//
//   appName, desktopEntry, summary, body, urgency, expireTimeout, transient
//
// Besides rewriting those, a rule may set:
//
//   kind       "chat" | "power" | "shell" | "alert" | "bell": the pictogram,
//              instead of guessing it from the app name.
//   duration   Milliseconds on screen, in place of the urgency default.
//   drop       true: never shown, never recorded.
//   silent     true: no toast; straight to history, like do-not-disturb.
//   bypassDnd  true: shown even under do-not-disturb.
//   appId      The window app id to focus on click, when the sender's name
//              is not it (a PWA, say).
//
// Anything else a rule sets (`origin` below) is scratch for later rules.
//
// A rule is { name, match, apply }. `match` is a function of the view, or
// an object whose every field must hold against the view: a RegExp is
// tested (no /g flag: test() would remember its position), a string is
// compared case-insensitively, anything else with ===. `apply` is a
// function of the view, or an object of fields to set. Every matching rule
// runs, in order, until one sets `drop` or carries `stop: true`.

var LOW = 0;
var NORMAL = 1;
var CRITICAL = 2;

var RULES = [
    // Chromium web notifications: the summary is the site's own title, and
    // the body opens with the tab's origin and a blank line. Pull the origin
    // out for the rules below, name the header after the site, and clear a
    // summary that just repeats the site name so the message moves up.
    {
        name: "chromium web app",
        match: {
            appName: /^(chromium|google-chrome|chrome|brave|vivaldi|microsoft-edge)/i,
            body: /^[a-z0-9.-]+\.[a-z]{2,}\n/i
        },
        apply: function (v) {
            var m = v.body.match(/^([a-z0-9.-]+)\n+([\s\S]*)$/i);
            v.origin = m[1].toLowerCase();
            v.body = m[2];
            var site = v.origin.replace(/^www\./, "").split(".")[0];
            v.appName = site;
            if (v.summary.toLowerCase() === site)
                v.summary = "";
        }
    },

    // Messenger writes "Sender: text" or "Sender to Group: text" as the
    // message. The sender line becomes the summary, the text the body.
    {
        name: "messenger",
        match: {
            origin: /(^|\.)messenger\.com$/
        },
        apply: function (v) {
            v.kind = "chat";
            var m = v.body.match(/^([^:\n]{1,80}): ([\s\S]+)$/);
            if (m) {
                v.summary = m[1];
                v.body = m[2];
            }
        }
    },

    {
        name: "google messages",
        match: {
            origin: /(^|\.)messages\.google\.com$/
        },
        apply: {
            kind: "chat"
        }
    },

    // Claude Code notifies through kitty with its own name as the summary
    // and a one-line body. Fold it to header plus one line.
    {
        name: "claude code",
        match: {
            appName: "kitty",
            summary: "Claude Code"
        },
        apply: function (v) {
            v.appName = "Claude";
            v.summary = v.body;
            v.body = "";
            v.kind = "shell";
        }
    },

    // The one thing that punches through do-not-disturb: a critical alert
    // from the bare CLI. Critical alone is not enough, because chat apps
    // mark everything critical to force visibility.
    {
        name: "cli alarm",
        match: {
            appName: "notify-send",
            urgency: CRITICAL
        },
        apply: {
            bypassDnd: true
        }
    }

    // Shapes for further tweaks:
    //
    // { name: "discord is not an emergency",
    //   match: { appName: /^discord$/i, urgency: CRITICAL },
    //   apply: { urgency: NORMAL } },
    //
    // { name: "quiet download chatter",
    //   match: { appName: /^chromium/i, summary: /^download complete$/i },
    //   apply: { silent: true } },
    //
    // { name: "never",
    //   match: function (v) { return /unsubscribe/i.test(v.body); },
    //   apply: { drop: true } },
];

function holds(view, field, want) {
    var have = view[field];
    if (want instanceof RegExp)
        return typeof have === "string" && want.test(have);
    if (typeof want === "string")
        return String(have === undefined || have === null ? "" : have).toLowerCase() === want.toLowerCase();
    return have === want;
}

function matches(rule, view) {
    if (typeof rule.match === "function")
        return rule.match(view) === true;
    for (var field in rule.match) {
        if (!holds(view, field, rule.match[field]))
            return false;
    }
    return true;
}

function process(view) {
    for (var i = 0; i < RULES.length; i++) {
        var rule = RULES[i];
        if (!matches(rule, view))
            continue;
        if (typeof rule.apply === "function") {
            rule.apply(view);
        } else {
            for (var key in rule.apply)
                view[key] = rule.apply[key];
        }
        if (view.drop === true || rule.stop === true)
            break;
    }
    return view;
}
