pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Minimal Bluetooth state via `bluetoothctl`. Enough to drive a toggle and show
 * whether the adapter is powered and if anything is connected.
 */
Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property string connectedName: ""
    readonly property bool connected: connectedName !== ""

    readonly property string icon: {
        if (!powered) return "bluetooth_disabled";
        if (connected) return "bluetooth_connected";
        return "bluetooth";
    }

    function toggle() {
        toggleProc.command = ["bluetoothctl", "power", powered ? "off" : "on"];
        toggleProc.running = true;
    }

    function openSettings() {
        Quickshell.execDetached(["blueman-manager"]);
    }

    Component.onCompleted: refresh()
    function refresh() {
        showProc.running = true;
        connProc.running = true;
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: showProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.trim().length > 0;
                root.powered = text.indexOf("Powered: yes") !== -1;
            }
        }
        onExited: (code) => { if (code !== 0) root.available = false; }
    }

    Process {
        id: connProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0] || "";
                // "Device AA:BB:CC:DD:EE:FF Name Of Device"
                const m = line.match(/^Device\s+\S+\s+(.*)$/);
                root.connectedName = m ? m[1] : "";
            }
        }
    }

    Process {
        id: toggleProc
        onExited: root.refresh()
    }
}
