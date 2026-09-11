pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "widgets" as Widgets

// The laptop module group.
//
// Every visibility decision lives in per-machine state (the "modules" map in
// settings.json), read through the Modules singleton; nothing is gated here.
// Each slot builds its widget only while its module is on, and the widget
// hides itself when its hardware is absent; a hidden item takes no room in
// the layout, so the bar closes up on the desktop as if none of this existed.
RowLayout {
    id: root

    required property var barScreen
    required property bool primary

    spacing: 11

    // With every module hidden (a desktop host, say) the widgets take no
    // room, but this RowLayout item itself would still sit in the outer
    // layout as a zero-width entry with spacing on both sides, doubling the
    // gap between the tray and the volume chip. Hide the row outright when
    // nothing in it can show. Read from the slots' `available` flags rather
    // than their `visible` props, because a child's effective visibility goes
    // false the moment this row hides, which would latch the row hidden.
    visible: {
        for (var i = 0; i < root.children.length; i++) {
            if (root.children[i].available)
                return true;
        }
        return false;
    }

    BarSlot {
        module: "system"
        sourceComponent: Widgets.SystemWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }

    BarSlot {
        module: "network"
        sourceComponent: Widgets.NetworkWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }

    BarSlot {
        module: "bluetooth"
        sourceComponent: Widgets.BluetoothWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }

    BarSlot {
        module: "controller"
        sourceComponent: Widgets.ControllerWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }

    BarSlot {
        module: "display"
        sourceComponent: Widgets.DisplayWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }

    BarSlot {
        module: "keyboard"
        sourceComponent: Widgets.KeyboardWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }

    BarSlot {
        module: "idle"
        sourceComponent: Widgets.IdleWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }

    BarSlot {
        module: "battery"
        sourceComponent: Widgets.BatteryWidget {
            barScreen: root.barScreen
            primary: root.primary
        }
    }
}
