.pragma library

// Text shaping for the character-LCD toast. Everything here works in
// characters, never pixels: the grid is a fixed number of monospace cells.

var ENTITIES = {
    "&amp;": "&",
    "&lt;": "<",
    "&gt;": ">",
    "&quot;": "\"",
    "&apos;": "'",
    "&#39;": "'",
    "&nbsp;": " "
};

// The server refuses body markup, so the toast renders plain text and a tag
// can never reach a parser. Clients that send markup anyway (Chromium web
// apps) just get their tags removed and entities unescaped.
function plain(text) {
    var out = String(text || "").replace(/<[^>]*>/g, "");
    out = out.replace(/&(amp|lt|gt|quot|apos|nbsp|#39);/g, function (m) {
        return ENTITIES[m];
    });
    return out.replace(/[ \t]+/g, " ").trim();
}

// Truncate to `columns` cells with a one-cell ellipsis.
function fit(text, columns) {
    var s = String(text || "");
    if (s.length <= columns)
        return s;
    if (columns <= 1)
        return "…";
    return s.slice(0, columns - 1).replace(/\s+$/, "") + "…";
}

// Wrap on word boundaries into at most `maxRows` rows of `columns` cells.
// Newlines are hard breaks; overlong words are cut. If anything is left over
// the last row ends in an ellipsis.
function wrap(text, columns, maxRows) {
    var rows = [];
    var paragraphs = String(text || "").split(/\r\n|\r|\n/);
    for (var p = 0; p < paragraphs.length; p++) {
        var words = paragraphs[p].split(" ").filter(function (w) {
            return w !== "";
        });
        var line = "";
        for (var i = 0; i < words.length; i++) {
            var word = words[i];
            while (word.length > columns) {
                if (line !== "") {
                    rows.push(line);
                    line = "";
                }
                rows.push(word.slice(0, columns));
                word = word.slice(columns);
            }
            var candidate = line === "" ? word : line + " " + word;
            if (candidate.length <= columns) {
                line = candidate;
            } else {
                rows.push(line);
                line = word;
            }
        }
        if (line !== "")
            rows.push(line);
    }
    if (rows.length > maxRows) {
        rows = rows.slice(0, maxRows);
        rows[maxRows - 1] = fit(rows[maxRows - 1] + " …", columns);
    }
    return rows;
}

// The header's app label. Reverse-DNS ids show their last segment.
function appLabel(appName, desktopEntry) {
    var name = String(appName || "");
    if (name === "")
        name = String(desktopEntry || "");
    if (name === "")
        return "SYSTEM";
    if (name.indexOf(".") > 0 && name.indexOf(" ") < 0) {
        var segments = name.split(".");
        name = segments[segments.length - 1];
    }
    return name.toUpperCase();
}
