import Quickshell.Io

// The IPC surface every popup chip offers: toggle, open and close, and
// focus, which opens with the keyboard cursor placed for the SUPER+T submap
// (hypr/submap-topbar.lua) and does nothing while the chip is hidden. A
// widget adds its own verbs after these.
//
// The widget's Ui.Popup is found by its id, `popup`, through the scope the
// handler is declared in: the handler itself cannot carry a property for
// it, since IpcHandler exports every property it has over IPC and rejects
// an object-typed one at load.
//
// Bars are instantiated per screen; the owner enables only the primary
// one's handler, or a second monitor collides with the target.
//
// `show`, `call`, `wait`, `listen` and `prop` are swallowed by the
// `qs ipc` CLI parser (see submap/SubmapOverlay.qml).
IpcHandler {
    // qmllint disable unqualified
    function toggle(): void {
        popup.toggle();
    }

    function open(): void {
        popup.open();
    }

    function close(): void {
        popup.close();
    }

    function focus(): void {
        if (popup.anchorItem && popup.anchorItem.visible)
            popup.openWithCursor();
    }
    // qmllint enable unqualified
}
