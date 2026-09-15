pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Bluetooth state via `bluetoothctl`: adapter power, connected device, and a
 * device list for the inline Bluetooth panel. Polls slowly; scans on demand.
 */
Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property string connectedName: ""
    property bool scanning: false

    // [{ mac, name, connected }]
    property var devices: []

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

    function connect(mac) {
        Quickshell.execDetached(["bluetoothctl", "connect", mac]);
    }
    function disconnect(mac) {
        Quickshell.execDetached(["bluetoothctl", "disconnect", mac]);
    }

    function scan() {
        if (scanning)
            return;
        scanning = true;
        // Kick a short discovery, then refresh the device list.
        Quickshell.execDetached(["sh", "-c", "bluetoothctl --timeout 6 scan on >/dev/null 2>&1 || true"]);
        refresh();
        scanTimer.restart();
    }

    function openSettings() {
        Quickshell.execDetached(["sh", "-c", "blueman-manager || overskride || true"]);
    }

    Component.onCompleted: refresh()
    function refresh() {
        showProc.running = true;
        devProc.running = true;
        connProc.running = true;
    }

    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: scanTimer
        interval: 6500
        onTriggered: { root.scanning = false; root.refresh(); }
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

    // Merge the "all devices" and "connected" lists once both have arrived.
    property var knownDevices: []
    property var connectedSet: ({})
    function combine() {
        const set = root.connectedSet || ({});
        const list = (root.knownDevices || []).map(d => ({
            mac: d.mac, name: d.name, connected: set[d.mac] === true
        }));
        list.sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));
        root.devices = list;
    }

    // All known devices → "Device MAC Name"
    Process {
        id: devProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const m = line.match(/^Device\s+(\S+)\s+(.*)$/);
                    if (m)
                        out.push({ mac: m[1], name: m[2] });
                }
                root.knownDevices = out;
                root.combine();
            }
        }
    }

    // Connected devices → mark them
    Process {
        id: connProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = ({});
                let first = "";
                for (const line of text.trim().split("\n")) {
                    const m = line.match(/^Device\s+(\S+)\s+(.*)$/);
                    if (m) { set[m[1]] = true; if (!first) first = m[2]; }
                }
                root.connectedName = first;
                root.connectedSet = set;
                root.combine();
            }
        }
    }

    Process { id: toggleProc; onExited: root.refresh() }
}
