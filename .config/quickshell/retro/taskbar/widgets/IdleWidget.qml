pragma ComponentBehavior: Bound

import QtQuick
import "../../ui" as Ui
import "../.."
import "../../services"

// The stay-awake toggle. Left click flips it; right click opens a readout
// of what is holding the screen awake right now, with nothing to choose.
// The chip is only the switch: the locks themselves are held by Idle and
// the bar window, so stay-awake outlives the chip being switched off.
//
// Three looks: urgent fill when stay-awake is forced here; plain fill with a
// lit glyph and a count when something else holds the screen (a game, a
// video); plain fill with a dim glyph when nothing does and the timeout
// will lock.
Ui.Chip {
    id: root

    required property var barScreen
    required property bool primary

    readonly property bool available: Modules.allow("idle", true)

    visible: root.available

    interactive: true
    fillColor: Idle.stayAwake ? Config.colors.urgent : Config.colors.shadow
    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton)
            popup.toggle();
        else
            Idle.toggle();
    }

    Ui.Glyph {
        anchors.verticalCenter: parent.verticalCenter
        slot: Config.settings.bar.iconSlot
        opacity: Idle.stayAwake || Idle.others > 0 ? 1 : 0.5
        text: "coffee"
    }

    Ui.Label {
        anchors.verticalCenter: parent.verticalCenter
        visible: !Idle.stayAwake && Idle.others > 0
        text: Idle.others
    }

    Ui.Popup {
        id: popup

        anchorItem: root
        barScreen: root.barScreen
        cardWidth: 340

        onOpenedChanged: Idle.watching = popup.opened

        Ui.SectionLabel {
            text: "Keeping awake"
        }

        Ui.PopupRow {
            interactive: false
            visible: Idle.inhibitors.length === 0
            text: "Nothing, locks on timeout"
        }

        Repeater {
            model: Idle.inhibitors

            Ui.PopupRow {
                required property var modelData

                interactive: false
                glyph: modelData.glyph
                text: modelData.text
                detail: modelData.detail
            }
        }
    }
}
