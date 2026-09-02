pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../modules" as Modules_
import ".."

// The laptop module group.
//
// Every visibility decision lives in modules.json, read through the Modules
// singleton; nothing is gated here. Each widget hides itself when its host
// says no or its hardware is absent, and a hidden item takes no room in the
// layout, so the bar closes up on the desktop as if none of this existed.
RowLayout {
    id: root

    required property var taskbarWindow
    required property var barScreen
    required property bool primary

    spacing: 11

    Modules_.NetworkWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Modules_.BluetoothWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Modules_.DisplayWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }

    Modules_.IdleWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
        taskbarWindow: root.taskbarWindow
    }

    Modules_.BatteryWidget {
        Layout.fillHeight: true
        barScreen: root.barScreen
        primary: root.primary
    }
}
