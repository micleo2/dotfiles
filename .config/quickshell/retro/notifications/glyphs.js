.pragma library

// 9x9 pixel maps for the toast's icon slot, drawn by osd/PixelGlyph: '#' is
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

var CHAT = ["signal", "discord", "telegram", "slack", "element", "matrix", "whatsapp", "messages", "thunderbird", "mail", "evolution", "geary", "beeper", "teams", "zulip", "irc", "weechat"];
var POWER = ["battery", "power", "upower", "charg"];
var SHELL = ["notify-send", "kitty", "terminal", "script", "cron", "systemd", "retro"];

function matches(haystack, needles) {
    for (var i = 0; i < needles.length; i++) {
        if (haystack.indexOf(needles[i]) >= 0)
            return true;
    }
    return false;
}

// `critical` is NotificationUrgency.Critical, passed in so this file stays
// free of QML imports.
function pick(appName, desktopEntry, summary, urgency, critical) {
    if (urgency === critical)
        return WARNING;
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
