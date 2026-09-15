pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Screen backlight control via `brightnessctl`. Degrades gracefully: if the
 * tool or a backlight device is missing, the slider just stays hidden.
 */
Singleton {
    id: root

    property int current: 0
    property int max: 1
    property bool available: false
    readonly property real fraction: max > 0 ? current / max : 0

    function set(frac) {
        const pct = Math.round(Math.max(0.01, Math.min(1, frac)) * 100);
        setProc.command = ["brightnessctl", "-m", "set", pct + "%"];
        setProc.running = true;
    }

    Component.onCompleted: refresh()
    function refresh() {
        readProc.running = true;
    }

    // `brightnessctl -m` prints: name,class,current,percent,max
    Process {
        id: readProc
        command: ["brightnessctl", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 5) {
                    root.current = parseInt(parts[2]) || 0;
                    root.max = parseInt(parts[4]) || 1;
                    root.available = root.max > 1;
                }
            }
        }
        onExited: (code) => { if (code !== 0) root.available = false; }
    }

    Process {
        id: setProc
        onExited: root.refresh()
    }
}
