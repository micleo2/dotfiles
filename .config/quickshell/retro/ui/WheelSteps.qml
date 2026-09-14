import QtQuick

// Scrolling as whole detents: `stepped` fires once per detent, direction +1
// or -1. Touchpads send a stream of sub-notch deltas rather than one event per
// detent, so the remainder is carried between events or a slow drag does
// nothing and a fast one jumps.
WheelHandler {
    id: root

    signal stepped(int direction)
    property real accumulator: 0

    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: (event) => {
        event.accepted = true;
        var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
        // One detent is 120 units. Clamp so a flung touchpad cannot
        // deliver a single enormous event.
        root.accumulator += Math.max(-120, Math.min(120, delta));
        while (Math.abs(root.accumulator) >= 120) {
            var direction = root.accumulator > 0 ? 1 : -1;
            root.accumulator -= direction * 120;
            root.stepped(direction);
        }
    }
}
