.pragma library

// 9x9 pixel maps for the toast's icon slot, drawn by lcd/PixelGlyph: '#' is
// lit, everything else is a ghost cell. Real app icons never look right on an
// LCD, so the slot shows what kind of thing arrived rather than who sent it.

var BELL = [
    "....#....",
    "...###...",
    "..#####..",
    "..#####..",
    "..#####..",
    "..#####..",
    ".#######.",
    ".........",
    "...###..."
];

var WARNING = [
    "....#....",
    "....#....",
    "...#.#...",
    "...#.#...",
    "..#...#..",
    "..#.#.#..",
    ".#..#..#.",
    ".#.....#.",
    "#########"
];

var ENVELOPE = [
    ".........",
    "#########",
    "#.......#",
    "##.....##",
    "#.#...#.#",
    "#..#.#..#",
    "#...#...#",
    "#.......#",
    "#########"
];

var BATTERY = [
    "...###...",
    ".#######.",
    ".#.....#.",
    ".#.....#.",
    ".#.###.#.",
    ".#.###.#.",
    ".#.###.#.",
    ".#######.",
    "........."
];

var TERMINAL = [
    "#########",
    "#.......#",
    "#.#.....#",
    "#..#....#",
    "#...#...#",
    "#..#....#",
    "#.#.....#",
    "#...####.",
    "#########"
];

var CHAT = ["signal", "discord", "telegram", "messenger", "slack", "element", "matrix", "whatsapp", "messages", "thunderbird", "mail", "evolution", "geary", "beeper", "teams", "zulip", "irc", "weechat"];
var POWER = ["battery", "power", "upower", "charg"];
var SHELL = ["notify-send", "kitty", "claude", "terminal", "script", "cron", "systemd", "retro"];

function matches(haystack, needles) {
    for (var i = 0; i < needles.length; i++) {
        if (haystack.indexOf(needles[i]) >= 0)
            return true;
    }
    return false;
}

// The kinds a rule in rules.js may name outright.
var KINDS = {
    "chat": ENVELOPE,
    "power": BATTERY,
    "shell": TERMINAL,
    "alert": WARNING,
    "bell": BELL
};

// `kind` is a rule's say, if it had one; otherwise the sender's names are
// guessed at. `critical` is NotificationUrgency.Critical, passed in so this
// file stays free of QML imports, and always wins: critical is the alarm.
function pick(kind, appName, desktopEntry, summary, urgency, critical) {
    if (urgency === critical)
        return WARNING;
    if (kind !== undefined && KINDS[kind] !== undefined)
        return KINDS[kind];
    var source = (String(appName || "") + "\n" + String(desktopEntry || "")).toLowerCase();
    var text = String(summary || "").toLowerCase();
    if (matches(source, POWER) || matches(text, POWER))
        return BATTERY;
    if (matches(source, CHAT))
        return ENVELOPE;
    if (matches(source, SHELL))
        return TERMINAL;
    return BELL;
}
