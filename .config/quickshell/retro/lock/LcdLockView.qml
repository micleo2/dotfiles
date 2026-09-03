pragma ComponentBehavior: Bound

import QtQuick
import "../lcd" as Lcd
import "../ui" as Ui
import ".."
import "../services"

// The lock screen as one Game & Watch LCD module in the OSD's frame: hard
// offset shadow, outlined bezel, dark face. Inside, a seven-segment clock,
// a character row with the date and who is logged in, and a character row
// for the password where every keystroke lights one cell and nothing is
// ever spelled out. The rest of the output is the outline colour, so the
// module sits in the dark the way the OSD does.
//
// Checking sweeps one lit cell along the password row until PAM answers.
// Denied turns the ink urgent, spells DENIED on the row and blinks the
// module the way a critical toast does; typing again clears it. The
// power-on flash of the character grids fires when the surface appears,
// and once more on the way out.
Item {
    id: root

    property bool inputEnabled: true
    property bool preview: false

    readonly property bool denied: Lock.denied
    readonly property color ink: root.denied ? Config.colors.urgent : Config.colors.text
    readonly property real ghost: 0.12
    readonly property int pad: 18
    readonly property int columns: 28

    readonly property date now: Time.now
    readonly property int hour12: (root.now.getHours() % 12) === 0 ? 12 : root.now.getHours() % 12
    readonly property int minutes: root.now.getMinutes()
    readonly property bool pm: root.now.getHours() >= 12
    readonly property bool colonOn: root.now.getSeconds() % 2 === 0
    readonly property string dateLabel: Qt.formatDate(root.now, "ddd MMM dd").toUpperCase()
    readonly property string whoLabel: root.denied ? "ERR " + (Lock.failedAttempts < 10 ? "0" : "") + Lock.failedAttempts : (Lock.userName + "@" + Lock.hostname).toUpperCase()
    readonly property int litCells: Math.min(root.columns, Lock.password.length)

    // The critical-toast alarm blink while denied.
    property bool blinkOn: true
    // Which cell the checking sweep is on.
    property int sweep: 0

    // One clock digit: the OSD's seven-segment at twice the size.
    component ClockDigit: Lcd.SevenSegment {
        width: 44
        height: 80
        thickness: 10
        ghost: root.ghost
        color: root.ink
    }

    function focusInput() {
        if (root.inputEnabled)
            input.forceActiveFocus();
    }

    function powerOn() {
        infoGrid.flash = true;
        passwordGrid.flash = true;
    }

    onInputEnabledChanged: {
        if (root.inputEnabled)
            Qt.callLater(root.focusInput);
    }

    onDeniedChanged: {
        if (!root.denied)
            root.blinkOn = true;
    }

    Component.onCompleted: Qt.callLater(root.focusInput)

    Connections {
        target: Lock

        function onUnlocked() {
            root.powerOn();
        }
    }

    Timer {
        running: root.denied
        interval: 250
        repeat: true
        onTriggered: root.blinkOn = !root.blinkOn
    }

    Timer {
        running: Lock.checking
        interval: 60
        repeat: true
        onTriggered: root.sweep = (root.sweep + 1) % root.columns
    }

    Rectangle {
        anchors.fill: parent
        color: Config.colors.outline
    }

    // Keys land here. Nothing of it is drawn; the cells below are the echo.
    TextInput {
        id: input

        width: 1
        height: 1
        opacity: 0
        enabled: root.inputEnabled && !Lock.checking
        echoMode: TextInput.Password
        passwordMaskDelay: 0
        text: Lock.password
        inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData

        onTextChanged: {
            if (text !== Lock.password)
                Lock.password = text;
            if (text.length > 0) {
                Lock.wake();
                if (Lock.denied)
                    Lock.clearDenied();
            }
        }

        onAccepted: {
            var submitted = Lock.password;
            if (submitted.length > 0)
                Lock.submit(submitted);
        }

        Keys.onPressed: (event) => {
            Lock.wake();
            if (event.key === Qt.Key_Escape || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U)) {
                if (root.preview && Lock.password.length === 0 && event.key === Qt.Key_Escape)
                    Lock.previewVisible = false;
                Lock.password = "";
                Lock.clearDenied();
                event.accepted = true;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: Lock.wake()
        onClicked: (mouse) => {
            Lock.wake();
            if (root.preview && mouse.button === Qt.RightButton) {
                Lock.previewVisible = false;
                return;
            }
            root.focusInput();
        }
    }

    // The frame language: hard offset shadow, outlined bezel, dark face.
    Rectangle {
        x: bezel.x + 4
        y: bezel.y + 4
        width: bezel.width
        height: bezel.height
        color: Config.colors.outline
    }

    Rectangle {
        id: bezel

        width: panel.implicitWidth + 2 * root.pad
        height: panel.implicitHeight + 2 * root.pad
        anchors.centerIn: parent
        color: Config.colors.base
        border.width: 2
        border.color: Config.colors.outline

        // The LCD face.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 8
            color: Config.colors.shadow
            border.width: 2
            border.color: Config.colors.outline
        }

        Column {
            id: panel

            anchors.centerIn: parent
            spacing: 16
            opacity: root.denied && !root.blinkOn ? 0.35 : 1

            // The clock: HH MM at twice the OSD's digit size, the colon
            // ticking the seconds, AM/PM in the pixel font. A leading zero
            // on the hour is left as a ghost, the OSD's rule.
            Item {
                width: infoGrid.width
                height: clock.height

                Row {
                    id: clock

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    ClockDigit {
                        // Every segment lit during the power-on flash.
                        digit: infoGrid.flash ? 8 : (root.hour12 >= 10 ? Math.floor(root.hour12 / 10) : -1)
                    }

                    ClockDigit {
                        digit: infoGrid.flash ? 8 : root.hour12 % 10
                    }

                    // Colon: two dots on the digit's own thickness.
                    Item {
                        width: 10
                        height: 80

                        Rectangle {
                            x: 0
                            y: Math.round(80 * 0.3) - 5
                            width: 10
                            height: 10
                            color: root.ink
                            opacity: infoGrid.flash || root.colonOn ? 1 : root.ghost
                        }

                        Rectangle {
                            x: 0
                            y: Math.round(80 * 0.7) - 5
                            width: 10
                            height: 10
                            color: root.ink
                            opacity: infoGrid.flash || root.colonOn ? 1 : root.ghost
                        }
                    }

                    ClockDigit {
                        digit: infoGrid.flash ? 8 : Math.floor(root.minutes / 10)
                    }

                    ClockDigit {
                        digit: infoGrid.flash ? 8 : root.minutes % 10
                    }
                }

                Ui.Label {
                    anchors.left: clock.right
                    anchors.leftMargin: 10
                    anchors.bottom: clock.bottom
                    text: root.pm ? "PM" : "AM"
                    color: root.ink
                    size: infoGrid.size
                    textFormat: Text.PlainText
                }
            }

            // Row: the date, and who this is (or how many times it was not).
            Lcd.CharGrid {
                id: infoGrid

                columns: root.columns
                rows: 1
                ghost: root.ghost

                Ui.Label {
                    x: 0
                    y: infoGrid.rowY(0)
                    height: infoGrid.cellHeight
                    text: root.dateLabel
                    color: root.ink
                    size: infoGrid.size
                    font.letterSpacing: infoGrid.letterSpacing
                    textFormat: Text.PlainText
                }

                Ui.Label {
                    x: (infoGrid.columns - root.whoLabel.length) * infoGrid.cellWidth
                    y: infoGrid.rowY(0)
                    height: infoGrid.cellHeight
                    text: root.whoLabel
                    color: root.ink
                    size: infoGrid.size
                    font.letterSpacing: infoGrid.letterSpacing
                    textFormat: Text.PlainText
                }
            }

            // Row: the password, one lit cell per character.
            Lcd.CharGrid {
                id: passwordGrid

                columns: root.columns
                rows: 1
                ghost: root.ghost

                // Lit cells, not text, so they go on the cell layer.
                marks: Repeater {
                    model: passwordGrid.columns

                    Rectangle {
                        required property int index

                        readonly property bool typed: !root.denied && !Lock.checking && index < root.litCells
                        readonly property bool sweeping: Lock.checking && index === root.sweep

                        x: index * passwordGrid.cellWidth
                        y: 0
                        width: passwordGrid.cellWidth - 1
                        height: passwordGrid.cellHeight - 1
                        color: root.ink
                        visible: typed || sweeping
                    }
                }

                Ui.Label {
                    readonly property string label: "DENIED"

                    visible: root.denied
                    x: Math.floor((passwordGrid.columns - label.length) / 2) * passwordGrid.cellWidth
                    y: passwordGrid.rowY(0)
                    height: passwordGrid.cellHeight
                    text: label
                    color: root.ink
                    size: passwordGrid.size
                    font.letterSpacing: passwordGrid.letterSpacing
                    textFormat: Text.PlainText
                }
            }
        }
    }
}
