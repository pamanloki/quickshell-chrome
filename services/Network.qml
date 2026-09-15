pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Network state via NetworkManager (`nmcli`). Exposes the active connection for
 * the shelf/quick-settings and a scannable list of Wi-Fi networks for the
 * inline Wi-Fi panel. Polls slowly; scans on demand.
 */
Singleton {
    id: root

    // "wifi" | "ethernet" | "disconnected"
    property string type: "disconnected"
    property string name: ""
    property int signal: 0        // 0..100, wifi only
    property bool wifiEnabled: true
    property bool scanning: false

    // [{ ssid, signal, security, active }]
    property var networks: []

    readonly property bool connected: type !== "disconnected"

    readonly property string icon: {
        if (type === "ethernet")
            return "settings_ethernet";
        if (type !== "wifi")
            return wifiEnabled ? "signal_wifi_off" : "wifi_off";
        if (signal >= 75) return "network_wifi";
        if (signal >= 50) return "network_wifi_3_bar";
        if (signal >= 25) return "network_wifi_2_bar";
        if (signal > 0)   return "network_wifi_1_bar";
        return "signal_wifi_statusbar_null";
    }

    function toggleWifi() {
        toggleProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        toggleProc.running = true;
    }

    function scan() {
        if (scanning)
            return;
        scanning = true;
        scanProc.running = true;
    }

    function connect(ssid) {
        if (!ssid)
            return;
        connProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        connProc.running = true;
    }

    function disconnect() {
        // Bring the active wifi connection down.
        Quickshell.execDetached(["sh", "-c",
            "nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 ~ /wireless/ {print $1}' | while read n; do nmcli connection down \"$n\"; done"]);
        root.refresh();
    }

    function openSettings() {
        Quickshell.execDetached(["sh", "-c",
            "nm-connection-editor || gnome-control-center wifi || plasma-systemsettings kcm_networkmanagement || true"]);
    }

    Component.onCompleted: refresh()
    function refresh() {
        statusProc.running = true;
        radioProc.running = true;
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Active connection: TYPE:STATE:CONNECTION for each device
    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = "disconnected", n = "", sig = 0;
                for (const line of text.trim().split("\n")) {
                    const f = line.split(":");
                    if (f.length < 3 || f[1] !== "connected")
                        continue;
                    if (f[0] === "ethernet") { t = "ethernet"; n = f[2]; break; }
                    if (f[0] === "wifi") { t = "wifi"; n = f[2]; }
                }
                root.type = t;
                root.name = n;
                if (t === "wifi")
                    signalProc.running = true;
                else
                    root.signal = 0;
            }
        }
    }

    Process {
        id: signalProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    if (line.startsWith("*")) {
                        root.signal = parseInt(line.split(":")[1]) || 0;
                        return;
                    }
                }
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim().indexOf("enabled") !== -1
        }
    }

    // Wi-Fi list (SSID last so colons in field 4+ can be rejoined)
    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                const seen = ({});
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const f = line.split(":");
                    if (f.length < 4)
                        continue;
                    const ssid = f.slice(3).join(":").trim();
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    out.push({
                        ssid: ssid,
                        signal: parseInt(f[1]) || 0,
                        security: f[2] || "",
                        active: f[0] === "*"
                    });
                }
                out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                root.networks = out;
            }
        }
        onExited: root.scanning = false
    }

    Process { id: toggleProc; onExited: root.refresh() }
    Process { id: connProc; onExited: root.refresh() }
}
