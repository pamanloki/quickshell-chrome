pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/** Basic host info for the About section. Read once at startup. */
Singleton {
    id: root

    property string host: Quickshell.env("HOSTNAME") || ""
    property string user: Quickshell.env("USER") || ""
    property string distro: ""
    property string kernel: ""
    property string uptime: ""
    property string wm: Quickshell.env("XDG_CURRENT_DESKTOP")
        || Quickshell.env("XDG_SESSION_DESKTOP") || "Wayland"

    function refresh() {
        distroProc.running = true;
        kernelProc.running = true;
        uptimeProc.running = true;
        if (!host) hostProc.running = true;
    }

    Component.onCompleted: refresh()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: uptimeProc.running = true }

    Process {
        id: distroProc
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null && printf %s \"$PRETTY_NAME\""]
        stdout: StdioCollector { onStreamFinished: root.distro = text.trim() }
    }
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        stdout: StdioCollector { onStreamFinished: root.kernel = text.trim() }
    }
    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p 2>/dev/null | sed 's/^up //'"]
        stdout: StdioCollector { onStreamFinished: root.uptime = text.trim() }
    }
    Process {
        id: hostProc
        command: ["uname", "-n"]
        stdout: StdioCollector { onStreamFinished: root.host = text.trim() }
    }
}
