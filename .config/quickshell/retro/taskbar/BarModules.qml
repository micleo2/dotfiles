pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../modules" as Modules_

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
    // nothing in it can show. Bound to the widgets' `available` flags rather
    // than their `visible` props, because a child's effective visibility goes
    // false the moment this row hides, which would latch the row hidden.
    visible: system.available || network.available || bluetooth.available || display.available || idle.available || battery.available

    Modules_.SystemWidget {
        id: system
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Modules_.NetworkWidget {
        id: network
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Modules_.BluetoothWidget {
        id: bluetooth
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Modules_.DisplayWidget {
        id: display
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Modules_.IdleWidget {
        id: idle
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
        taskbarWindow: root.taskbarWindow
    }

    Modules_.BatteryWidget {
        id: battery
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }
}
