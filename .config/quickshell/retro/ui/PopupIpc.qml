import Quickshell.Io

// The IPC surface every popup chip offers: toggle, open and close, and
// focus, which opens with the keyboard cursor placed for the SUPER+T submap
// (hypr/submap-topbar.lua). Nothing opens while the chip is hidden: the
// card would hang at a phantom spot under a chip that is not there. A
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
    function shown(): bool {
        return popup.anchorItem && popup.anchorItem.visible;
    }

    function toggle(): void {
        if (popup.opened)
            popup.close();
        else if (shown())
            popup.open();
    }

    function open(): void {
        if (shown())
            popup.open();
    }

    function close(): void {
        popup.close();
    }

    function focus(): void {
        if (shown())
            popup.openWithCursor();
    }
    // qmllint enable unqualified
}
