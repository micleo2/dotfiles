pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import "../../ui" as Ui
import "../.."
import "../../services"

Ui.Chip {
    id: root

    required property var barScreen
    required property bool primary

    readonly property var battery: UPower.displayDevice
    readonly property bool available: Modules.allow("battery", Host.isLaptop)

    // UPower reports a 0-1 fraction, not a percentage.
    readonly property int percent: root.battery ? Math.round(root.battery.percentage * 100) : 0
    readonly property bool charging: root.battery && (root.battery.state === UPowerDeviceState.Charging || root.battery.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: root.battery && root.battery.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !root.charging && !root.full && root.percent <= 15

    visible: root.available

    function glyph() {
        if (root.charging)
            return "battery_charging_full";
        if (root.low)
            return "battery_alert";
        if (root.percent >= 95)
            return "battery_full";
        // battery_0_bar .. battery_6_bar covers the rest in even steps.
        return "battery_" + Math.max(0, Math.min(6, Math.round(root.percent / 100 * 6))) + "_bar";
    }

    function profileName(profile) {
        // PowerProfile.toString gives the enum spelling ("PowerSaver").
        if (profile === PowerProfile.PowerSaver)
            return "Power saver";
        if (profile === PowerProfile.Performance)
            return "Performance";
        return "Balanced";
    }

    function duration(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.round((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    interactive: true
    onClicked: popup.toggle()

    Ui.Glyph {
        anchors.verticalCenter: parent.verticalCenter
        color: root.low ? Config.colors.urgent : Config.colors.text
        text: root.glyph()
    }

    Ui.Label {
        anchors.verticalCenter: parent.verticalCenter
        color: root.low ? Config.colors.urgent : Config.colors.text
        text: root.percent + "%"
    }

    Ui.Popup {
        id: popup

        anchorItem: root
        barScreen: root.barScreen
        cardWidth: 340

        Ui.SectionLabel {
            text: "Battery"
        }

        Ui.PopupRow {
            interactive: false
            glyph: root.glyph()
            text: {
                if (root.full)
                    return "Fully charged";
                return root.charging ? "Charging" : "On battery";
            }
            detail: root.percent + "%"
        }

        Ui.PopupRow {
            interactive: false
            visible: root.battery && (root.charging ? root.battery.timeToFull > 0 : root.battery.timeToEmpty > 0)
            text: root.charging ? "Until full" : "Remaining"
            detail: root.battery ? root.duration(root.charging ? root.battery.timeToFull : root.battery.timeToEmpty) : ""
        }

        Ui.PopupRow {
            interactive: false
            text: root.charging ? "Charge rate" : "Draw"
            detail: root.battery ? root.battery.changeRate.toFixed(1) + " W" : ""
        }

        Ui.PopupRow {
            interactive: false
            visible: root.battery && root.battery.healthSupported
            text: "Health"
            detail: root.battery ? Math.round(root.battery.healthPercentage) + "%" : ""
        }

        Ui.SectionLabel {
            text: "History"
        }

        Ui.PopupRow {
            interactive: false
            visible: BatteryHistory.error !== ""
            text: BatteryHistory.error
        }

        Ui.HistoryBars {
            rowKey: "history"

            visible: BatteryHistory.error === ""
            series: BatteryHistory.series
            divisions: ticks.divisions
            // One bucket per 2px column, so the columns tile the card exactly.
            onWidthChanged: BatteryHistory.buckets = Math.max(1, Math.floor(width / 2))
            onStepped: (direction) => BatteryHistory.cycle(direction)
        }

        Ui.HistoryTicks {
            id: ticks

            visible: BatteryHistory.error === ""
            span: BatteryHistory.span
        }

        Ui.SectionLabel {
            text: "Power profile"
        }

        Repeater {
            // power-profiles-daemon does not offer Performance on every machine;
            // showing a stop that cannot be selected would just be a dead row.
            model: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]

            Ui.PopupRow {
                required property var modelData

                rowKey: "profile:" + modelData

                text: root.profileName(modelData)
                selected: PowerProfiles.profile === modelData
                onClicked: PowerProfiles.profile = modelData
            }
        }
    }

    // The history is only as fresh as the popup: fetched on open, never polled.
    Connections {
        target: popup

        function onOpenedChanged() {
            if (popup.opened)
                BatteryHistory.refresh();
        }
    }

    Ui.PopupIpc {
        target: "battery"
        enabled: root.primary
    }
}
