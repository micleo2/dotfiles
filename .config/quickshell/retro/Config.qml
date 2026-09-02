import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    FontLoader {
        id: mainFontLoader

        source: "fonts/CozetteVector.ttf"
    }
    readonly property string mainFont: mainFontLoader.name

    // Bundled with the config and previously loaded-but-unused in shell.qml.
    // Has GSUB ligatures, so `text: "wifi"` renders the glyph by name.
    FontLoader {
        id: iconFontLoader

        source: "fonts/MaterialSymbolsSharp_Filled_36pt-Regular.ttf"
    }
    readonly property string iconFont: iconFontLoader.name

    // The palette in use, chosen by name in the display popup and persisted
    // in Settings. Any entry added to `themes` below shows up there.
    readonly property var colors: root.themes[Settings.theme] !== undefined ? root.themes[Settings.theme] : root.themes.default
    readonly property var themeNames: Object.keys(root.themes)

    property var themes: {
        "default": {
            "base": "#d8d8d8",
            "shadow": "#9b9b9b",
            "highlight": "#efefef",
            "urgent": "#ff723e",
            "accent": "#207874",
            "text": "#000000",
            "outline": "#000000",
            "outlineGradientFade": "#161616",
            "defaultWallpaperPath": ""
        },
        "yorha": {
            "base": "#d9caba",
            "shadow": "#baafa1",
            "highlight": "#f0e2d3",
            "urgent": "#ff854c",
            "accent": "#626335",
            "text": "#3e3d38",
            "outline": "#3d3d39",
            "outlineGradientFade": "#5b5b45",
            "defaultWallpaperPath": ""
        },
        "cherry": {
            "base": "#f4c9ef",
            "shadow": "#c7a4cc",
            "highlight": "#f9d0f7",
            "urgent": "#ff936c",
            "accent": "#c950bb",
            "text": "#321d32",
            "outline": "#20091d",
            "outlineGradientFade": "#3e233e",
            "defaultWallpaperPath": ""
        },
        "indigo": {
            "base": "#bac4e6",
            "shadow": "#7e8bad",
            "highlight": "#d0def9",
            "urgent": "#e83939",
            "accent": "#3e7c99",
            "text": "#0d0d19",
            "outline": "#1a2135",
            "outlineGradientFade": "#223143",
            "defaultWallpaperPath": ""
        },
        "gleep": {
            "base": "#bae6c5",
            "shadow": "#93c48c",
            "highlight": "#ccf9e7",
            "urgent": "#ff7559",
            "accent": "#3e9949",
            "text": "#0d1913",
            "outline": "#21351a",
            "outlineGradientFade": "#284223",
            "defaultWallpaperPath": ""
        },
        // Phosphor on black. Text and outlines share the one green, so every
        // frame, edge and drop shadow reads as a lit trace on a dark tube.
        "matrix": {
            "base": "#000000",
            "shadow": "#0a3d16",
            "highlight": "#0f5a22",
            "urgent": "#ffb000",
            "accent": "#00ff41",
            "text": "#00ff41",
            "outline": "#00ff41",
            "outlineGradientFade": "#00b32d",
            "defaultWallpaperPath": ""
        }
    }
    property var settings

    settings: JsonObject {
        property JsonObject bar

        bar: JsonObject {
            // Anchored so the default 12px text size reproduces the original 22.
            property int fontSize: Math.round(22 * Settings.textSizePx / 12)
            property int trayIconSize: 18
            property bool monochromeTrayIcons: true
        }

    }

}
