import QtQuick
import ".."

// A single-line text entry, used for wifi passphrases.
Item {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool echoHidden: true

    signal accepted(string value)

    implicitWidth: parent ? parent.width : 0
    implicitHeight: 30

    function take() {
        input.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        color: Config.colors.base
        border.width: 2
        border.color: Config.colors.outline
    }

    Label {
        anchors.fill: parent
        anchors.leftMargin: 6
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        opacity: 0.5
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        verticalAlignment: Text.AlignVCenter
        clip: true

        color: Config.colors.text
        selectionColor: Config.colors.shadow
        selectedTextColor: Config.colors.text
        selectByMouse: true

        echoMode: root.echoHidden ? TextInput.Password : TextInput.Normal
        passwordCharacter: "*"
        passwordMaskDelay: 0

        font.family: Config.mainFont
        font.pixelSize: Config.settings.bar.fontSize

        // Return is taken here and accepted. TextInput itself ignores it, so
        // it would otherwise bubble to the popup card after the field has
        // hidden itself and read as "activate the row" a second time. Escape
        // is left alone on purpose: the card turns it into "back to the list".
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.accepted(input.text);
                event.accepted = true;
            } else if (Readline.handle(input, event)) {
                event.accepted = true;
            }
        }
    }
}
