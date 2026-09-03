pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Audio output: level, mute, and which device is playing.
//
// Everything reads through the one `ready` gate. The previous version
// dereferenced Pipewire.defaultAudioSink unguarded, which is where the
// "Cannot read property 'audio' of null" warnings at every startup came from —
// PipeWire resolves a moment after the shell does.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: root.sink !== null && root.sink.ready && root.sink.audio !== null

    readonly property real level: root.ready ? root.sink.audio.volume : 0
    readonly property int percent: Math.round(root.level * 100)
    // One keypress or wheel detent moves this much; the OSD draws one bar
    // per step so every press visibly lands.
    readonly property int stepPercent: 5
    readonly property int segments: Math.round(100 / root.stepPercent)
    readonly property bool muted: root.ready && root.sink.audio.muted

    // ------------------------------------------------------------- devices --

    readonly property var candidateSinks: {
        var out = [];
        var nodes = Pipewire.nodes ? Pipewire.nodes.values : [];
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (node.isSink && !node.isStream)
                out.push(node);
        }
        return out;
    }

    // Playback streams publish as stream sinks; capture streams as stream
    // sources.
    readonly property var candidateStreams: {
        var out = [];
        var nodes = Pipewire.nodes ? Pipewire.nodes.values : [];
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (node.isSink && node.isStream)
                out.push(node);
        }
        return out;
    }

    // Binding the nodes is what makes `properties` and `audio` valid on them.
    // Tracking only the default sink is enough to show a level, but not to
    // build a device list.
    PwObjectTracker {
        objects: root.candidateSinks
    }

    PwObjectTracker {
        objects: root.candidateStreams
    }

    // The Repeater is fed from this snapshot rather than from candidateSinks
    // directly, and only while a popup is looking at it. PipeWire can remove a
    // node while Quickshell is still dispatching the removal signal, and
    // rebuilding a Repeater from that signal path has crashed Quickshell's
    // PipeWire service — so the rebuild is pushed onto a later tick.
    property var displaySinks: []
    property var displayStreams: []

    // Fired by the shell's own volume actions (chip scroll, IPC, mute), so
    // the OSD flashes for those and not for a change made elsewhere.
    signal changed
    property bool watching: false

    onCandidateSinksChanged: {
        if (root.watching)
            snapshotDebounce.restart();
    }

    onCandidateStreamsChanged: {
        if (root.watching)
            snapshotDebounce.restart();
    }

    onWatchingChanged: {
        if (root.watching) {
            snapshotDebounce.restart();
        } else {
            root.displaySinks = [];
            root.displayStreams = [];
        }
    }

    Timer {
        id: snapshotDebounce

        interval: 75
        onTriggered: {
            root.displaySinks = root.candidateSinks.slice();
            root.displayStreams = root.candidateStreams.slice();
        }
    }

    // -------------------------------------------------------------- labels --

    function nodeProps(node) {
        // Invalid until the node is bound; reading it early destabilises the
        // PipeWire service.
        return node && node.ready && node.properties ? node.properties : {};
    }

    function tidy(text) {
        return String(text || "").trim().replace(/^built-?in audio\s+/i, "").replace(/\s+(Output|Input)$/i, "").trim();
    }

    // Profile description first. Omarchy leads with the nickname, but on this
    // hardware that is "ALC285 Analog" for both the speakers and the headset
    // microphone, while the profile description is "Speaker" and "Headset Mono
    // Microphone" — the names a person would actually use.
    function baseLabel(node) {
        if (!node)
            return "";
        var props = root.nodeProps(node);
        var candidates = [props["device.profile.description"], node.nickname, props["node.nick"], node.description, node.name];
        for (var i = 0; i < candidates.length; i++) {
            var text = root.tidy(candidates[i]);
            if (text !== "")
                return text;
        }
        return "Unknown";
    }

    // A profile description is only unique within its own device, so two cards
    // can both call their output "Speaker". Where that happens, fall back to
    // the fully qualified description for the ones that collide.
    readonly property var labels: {
        var counts = {};
        var list = root.displaySinks;
        var i;
        for (i = 0; i < list.length; i++) {
            var base = root.baseLabel(list[i]);
            counts[base] = (counts[base] || 0) + 1;
        }
        var out = {};
        for (i = 0; i < list.length; i++) {
            var node = list[i];
            var label = root.baseLabel(node);
            out[node.id] = counts[label] > 1 ? root.tidy(node.description || node.name) : label;
        }
        return out;
    }

    function label(node) {
        if (!node)
            return "";
        var resolved = root.labels[node.id];
        return resolved !== undefined ? resolved : root.baseLabel(node);
    }

    function streamLabel(node) {
        if (!node)
            return "";
        var props = root.nodeProps(node);
        var candidates = [props["application.name"], node.description, props["media.name"], node.name];
        for (var i = 0; i < candidates.length; i++) {
            var text = root.tidy(candidates[i]);
            if (text !== "")
                return text;
        }
        return "Unknown";
    }

    function streamVolume(node) {
        return node && node.audio ? node.audio.volume : 0;
    }

    function streamMuted(node) {
        return node && node.audio ? node.audio.muted : false;
    }

    function glyphFor(node) {
        if (!node)
            return "speaker";
        var props = root.nodeProps(node);
        var blob = [node.name, node.description, node.nickname, props["device.icon-name"], props["device.icon_name"]].join(" ").toLowerCase();
        if (/headphone|headset|earbud|earphone|airpod/.test(blob))
            return "headphones";
        if (/bluetooth|bluez/.test(blob))
            return "bluetooth";
        if (/hdmi|displayport|\bdp\b/.test(blob))
            return "tv";
        if (/usb/.test(blob))
            return "usb";
        return "speaker";
    }

    // ------------------------------------------------------------- actions --

    function setVolume(value) {
        if (!root.ready)
            return;
        // No over-amplification: the output slider stops at 100%, as omarchy's
        // does. Its per-stream sliders go above; the ones here do not.
        root.sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    // Per-stream moves stay off the OSD: `changed` is for the output level.
    function setStreamVolume(node, value) {
        if (!node || !node.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleStreamMute(node) {
        if (!node || !node.audio)
            return;
        node.audio.muted = !node.audio.muted;
    }

    function adjust(delta) {
        root.setVolume(root.level + delta);
        root.changed();
    }

    function toggleMute() {
        if (!root.ready)
            return;
        root.sink.audio.muted = !root.sink.audio.muted;
        root.changed();
    }

    // Omarchy pairs this with a CLI that also runs `pactl set-default-sink` and
    // walks every sink-input onto the new device, because Quickshell has no API
    // for moving streams that are already playing. Measured here, that is not
    // needed: with the shell-out stubbed out, a running pw-play stream still
    // followed the switch, because WirePlumber moves any stream that has not
    // pinned an explicit target — which is nearly all of them. An application
    // that does pin its target would stay put, but none is doing so here, and
    // shelling out on every switch to cover a case that does not arise is not
    // worth the dependency.
    function setSink(node) {
        if (!node)
            return;
        Pipewire.preferredDefaultAudioSink = node;
    }
}
