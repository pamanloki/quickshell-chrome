pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Network state derived from NetworkManager via `nmcli`. Polls periodically and
 * exposes a simple connection type / name / signal for the shelf & quick
 * settings. Toggling Wi-Fi shells out to `nmcli radio wifi on|off`.
 */
Singleton {
    id: root

    // "wifi" | "ethernet" | "disconnected"
    property string type: "disconnected"
    property string name: ""
    property int signal: 0        // 0..100, wifi only
    property bool wifiEnabled: true

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

    function openSettings() {
        Quickshell.execDetached(["nm-connection-editor"]);
    }

    Component.onCompleted: refresh()
    function refresh() {
        statusProc.running = true;
        radioProc.running = true;
    }

    Timer {
        interval: 5000
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
                let t = "disconnected", n = "", best = 0;
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
            }
        }
    }

    // Signal strength of the active wifi AP
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

    Process {
        id: toggleProc
        onExited: root.refresh()
    }
}
