pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var colors: themes.default
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
        }
    }

    property JsonObject settings: JsonObject {
        property JsonObject bar: JsonObject {
            property int fontSize: 12
            property int trayIconSize: 16
            property bool monochromeTrayIcons: true
        }
    }
}
