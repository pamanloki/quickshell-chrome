pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Live CPU / memory / temperature / disk stats for the Device settings pane.
 * Polling only runs while `active` is true (the pane sets it while visible),
 * so nothing samples in the background — no idle CPU wakeups, no heat.
 */
Singleton {
    id: root

    property bool active: false

    property int cpu: 0            // %
    property int memUsedMiB: 0
    property int memTotalMiB: 0
    property int memPct: 0
    property int temp: 0          // °C (0 = unavailable)
    property string diskUsed: ""  // e.g. "42G"
    property string diskTotal: "" // e.g. "100G"
    property int diskPct: 0

    property var _prev: null       // { total, idle } from last /proc/stat

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    Process {
        id: statProc
        command: ["sh", "-c",
            "cpu=$(head -n1 /proc/stat); "
            + "mem=$(awk '/^MemTotal:|^MemAvailable:/{printf \"%s \", $2}' /proc/meminfo); "
            + "t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); "
            + "d=$(df -h --output=used,size,pcent / 2>/dev/null | tail -n1); "
            + "printf '%s|%s|%s|%s' \"$cpu\" \"$mem\" \"$t\" \"$d\""]
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }

    function _parse(out) {
        const parts = (out || "").split("|");

        // CPU: "cpu  user nice system idle iowait irq softirq steal ..."
        const vals = (parts[0] || "").trim().split(/\s+/).slice(1).map(x => parseInt(x) || 0);
        if (vals.length >= 5) {
            const idle = vals[3] + vals[4];
            let total = 0;
            for (const v of vals) total += v;
            if (root._prev) {
                const dt = total - root._prev.total;
                const di = idle - root._prev.idle;
                if (dt > 0) root.cpu = Math.max(0, Math.min(100, Math.round(100 * (dt - di) / dt)));
            }
            root._prev = { total: total, idle: idle };
        }

        // Memory (kB): "MemTotal MemAvailable"
        const mem = (parts[1] || "").trim().split(/\s+/).map(x => parseInt(x) || 0);
        if (mem.length >= 2 && mem[0] > 0) {
            root.memTotalMiB = Math.round(mem[0] / 1024);
            root.memUsedMiB = Math.round((mem[0] - mem[1]) / 1024);
            root.memPct = Math.round(100 * (mem[0] - mem[1]) / mem[0]);
        }

        // Temperature (milli-°C or °C)
        const t = parseInt((parts[2] || "0").trim()) || 0;
        root.temp = t > 1000 ? Math.round(t / 1000) : t;

        // Disk: "used size pcent" e.g. "42G 100G 45%"
        const d = (parts[3] || "").trim().split(/\s+/);
        if (d.length >= 3) {
            root.diskUsed = d[0];
            root.diskTotal = d[1];
            root.diskPct = parseInt(d[2]) || 0;
        }
    }
}
