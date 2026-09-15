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

    // Battery % per device mac (from `bluetoothctl info`), -1 if unknown.
    property var batteryMap: ({})
    function batteryOf(mac) {
        const v = root.batteryMap[mac];
        return (v === undefined) ? -1 : v;
    }
    function _queryBattery(macs) {
        if (!macs || macs.length === 0) { root.batteryMap = ({}); return; }
        batteryProc.command = ["sh", "-c",
            "for m in \"$@\"; do "
            + "p=$(bluetoothctl info \"$m\" 2>/dev/null | grep -m1 'Battery Percentage' "
            + "| grep -oE '\\(([0-9]+)\\)' | tr -d '()'); "
            + "printf '%s %s\\n' \"$m\" \"$p\"; done",
            "sh"].concat(macs);
        batteryProc.running = true;
    }
    Process {
        id: batteryProc
        stdout: StdioCollector {
            onStreamFinished: {
                const map = ({});
                for (const line of text.trim().split("\n")) {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 2) {
                        const p = parseInt(parts[1]);
                        if (!isNaN(p)) map[parts[0]] = p;
                    }
                }
                root.batteryMap = map;
            }
        }
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
                root._queryBattery(Object.keys(set));
            }
        }
    }

    Process { id: toggleProc; onExited: root.refresh() }
}
