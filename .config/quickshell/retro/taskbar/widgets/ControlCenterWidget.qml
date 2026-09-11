pragma ComponentBehavior: Bound

import QtQuick
import "../../ui" as Ui
import "../.."
import "../../services"

// The switchboard for the rest of the bar: one toggle per widget. Off
// means gone, not hidden (BarSlot), so a widget switched off here costs
// nothing at all. The choice is machine-local state (Modules).
Ui.Chip {
    id: root

    required property var barScreen
    required property bool primary

    // Always shown: it is the way back for everything else.
    readonly property bool available: true

    interactive: true
    onClicked: popup.toggle()

    Ui.Glyph {
        anchors.verticalCenter: parent.verticalCenter
        slot: Config.settings.bar.iconSlot
        text: "tune"
    }

    Ui.Popup {
        id: popup

        anchorItem: root
        barScreen: root.barScreen
        // The chip is at the left edge; a right-aligned card would run off it.
        alignRight: false
        cardWidth: 280

        Ui.SectionLabel {
            text: "Widgets"
        }

        Repeater {
            model: Modules.list

            Ui.PopupToggle {
                required property var modelData

                rowKey: "module:" + modelData.id

                text: modelData.label
                checked: Modules.on(modelData.id)
                onToggled: (value) => Modules.set(modelData.id, value)
            }
        }
    }

    Ui.PopupIpc {
        target: "control"
        enabled: root.primary

        // Flip one module by id from a keybind: "on", "off", or nothing to
        // toggle. Returns what it is now.
        function module(id: string, state: string): string {
            if (Modules.entry(id) === null)
                return "no module " + id + " (have " + Modules.list.map(e => e.id).join(" ") + ")";
            var want = String(state || "");
            if (want === "on")
                Modules.set(id, true);
            else if (want === "off")
                Modules.set(id, false);
            else
                Modules.set(id, !Modules.on(id));
            return id + " " + (Modules.on(id) ? "on" : "off");
        }
    }
}
