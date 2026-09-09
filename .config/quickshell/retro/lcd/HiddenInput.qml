import QtQuick

// Where an LCD module's keys land. Nothing of it is drawn; the module's
// cells are the echo. It takes keyboard focus whenever the module becomes
// the active one (`active` is the owner's inputEnabled) and on a click,
// through grab(). A module with no line to edit sets readOnly and just
// reads Keys.onPressed.
TextInput {
    id: root

    property bool active: true

    width: 1
    height: 1
    opacity: 0
    enabled: root.active
    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

    function grab() {
        if (root.active)
            root.forceActiveFocus();
    }

    onActiveChanged: {
        if (root.active)
            Qt.callLater(root.grab);
    }

    Component.onCompleted: Qt.callLater(root.grab)
}
