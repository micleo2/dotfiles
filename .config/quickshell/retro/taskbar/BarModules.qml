pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "widgets" as Widgets

// The laptop module group.
//
// Every visibility decision lives in per-machine state (the "modules" map in
// settings.json), read through the Modules singleton; nothing is gated here.
// Each widget hides itself when its host says no or its hardware is absent,
// and a hidden item takes no room in the layout, so the bar closes up on the
// desktop as if none of this existed.
RowLayout {
    id: root

    required property var taskbarWindow
    required property var barScreen
    required property bool primary

    spacing: 11

    // With every module hidden (a desktop host, say) the widgets take no
    // room, but this RowLayout item itself would still sit in the outer
    // layout as a zero-width entry with spacing on both sides, doubling the
    // gap between the tray and the volume chip. Hide the row outright when
    // nothing in it can show. Read from the widgets' `available` flags rather
    // than their `visible` props, because a child's effective visibility goes
    // false the moment this row hides, which would latch the row hidden.
    visible: {
        for (var i = 0; i < root.children.length; i++) {
            if (root.children[i].available)
                return true;
        }
        return false;
    }

    Widgets.SystemWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Widgets.NetworkWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Widgets.BluetoothWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Widgets.ControllerWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Widgets.DisplayWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Widgets.KeyboardWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Widgets.IdleWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
        taskbarWindow: root.taskbarWindow
    }

    Widgets.BatteryWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }
}
