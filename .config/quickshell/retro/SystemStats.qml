pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and GPU load, for the system overview module.
//
// CPU comes from /proc/stat deltas. GPU comes from nvidia-smi, and its absence
// is the guard: gpuAvailable turns true only after a successful read, so a
// machine without the tool or the card (the laptop) just never grows the GPU
// half of the widget. The probe answers NOGPU once and polling stops for good.
// An amdgpu machine would read sysfs instead; none exists here yet.
Singleton {
    id: root

    // Nothing polls unless some machine actually enabled the module.
    readonly property bool enabled: Modules.allow("system", true)

    // 0-100. Stays 0 until the second sample provides a delta.
    property int cpuPercent: 0
    property double _prevBusy: 0
    property double _prevTotal: 0

    property bool gpuAvailable: false
    property bool _gpuGone: false
    property int gpuPercent: 0
    property double vramUsedMib: 0
    property double vramTotalMib: 0
    readonly property int vramPercent: root.vramTotalMib > 0 ? Math.round(root.vramUsedMib / root.vramTotalMib * 100) : 0

    Process {
        id: cpuProc

        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                var fields = text.split("\n")[0].trim().split(/\s+/);
                // cpu user nice system idle iowait irq softirq steal ...
                var total = 0;
                for (var i = 1; i < fields.length; i++)
                    total += parseInt(fields[i], 10) || 0;
                var idle = (parseInt(fields[4], 10) || 0) + (parseInt(fields[5], 10) || 0);
                var busy = total - idle;
                var dTotal = total - root._prevTotal;
                if (root._prevTotal > 0 && dTotal > 0)
                    root.cpuPercent = Math.round(Math.max(0, Math.min(100, (busy - root._prevBusy) / dTotal * 100)));
                root._prevTotal = total;
                root._prevBusy = busy;
            }
        }
    }

    Process {
        id: gpuProc

        // Through sh so a missing nvidia-smi is an answer, not a spawn error.
        command: ["sh", "-c", "command -v nvidia-smi >/dev/null 2>&1 && exec nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits; echo NOGPU"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim().split("\n")[0];
                if (line === "" || line === "NOGPU" || line.indexOf(",") === -1) {
                    root._gpuGone = true;
                    root.gpuAvailable = false;
                    return;
                }
                var parts = line.split(",");
                root.gpuPercent = parseInt(parts[0], 10) || 0;
                root.vramUsedMib = parseFloat(parts[1]) || 0;
                root.vramTotalMib = parseFloat(parts[2]) || 0;
                root.gpuAvailable = true;
            }
        }
    }

    Timer {
        interval: 2000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: cpuProc.running = true
    }

    Timer {
        interval: 3000
        running: root.enabled && !root._gpuGone
        repeat: true
        triggeredOnStart: true
        onTriggered: gpuProc.running = true
    }
}
