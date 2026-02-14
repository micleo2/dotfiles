pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Services.Pipewire

Singleton {
    id: root
    // Bind the pipewire node so its volume will be tracked
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio
    }

    readonly property string volume: {
      Pipewire.defaultAudioSink.audio.muted ?
      "󰝟" 
      :`󰕾 ${Math.round(Pipewire.defaultAudioSink.audio.volume * 100)}%`;
    }
}
