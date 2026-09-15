pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Self-contained night light (blue-light filter). Holds a constant colour
 * temperature with `wlsunset` (falling back to `gammastep`); both restore the
 * gamma when killed. The chosen temperature is persisted. No external script
 * needed.
 */
Singleton {
    id: root

    property bool active: false
    property int temp: 4000
    readonly property int minTemp: 2500
    readonly property int maxTemp: 6500
    readonly property real fraction: (temp - minTemp) / (maxTemp - minTemp)

    readonly property string statePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshell-chrome/nightlight.json"

    function enable()  { active = true;  _apply(); _save(); }
    function disable() {
        active = false;
        Quickshell.execDetached(["sh", "-c",
            "pkill -x wlsunset 2>/dev/null; pkill -x gammastep 2>/dev/null; gammastep -x >/dev/null 2>&1 || true"]);
        _save();
        settle.restart();
    }
    function toggle() { active ? disable() : enable(); }

    function setTemp(k) {
        temp = Math.max(minTemp, Math.min(maxTemp, Math.round(k)));
        _save();
        if (active)
            applyTimer.restart();     // debounce while dragging the slider
    }
    function warmer() { setTemp(temp - 200); }
    function cooler() { setTemp(temp + 200); }

    // Force a constant temperature: day = K+1, night = K, with a 1-minute
    // "day" window so it stays at K nearly all the time.
    function _apply() {
        Quickshell.execDetached(["sh", "-c",
              "K=$1; pkill -x wlsunset 2>/dev/null; pkill -x gammastep 2>/dev/null; "
            + "if command -v wlsunset >/dev/null 2>&1; then "
            + "  wlsunset -T $((K+1)) -t $K -S 00:00 -s 00:01 >/dev/null 2>&1 & "
            + "elif command -v gammastep >/dev/null 2>&1; then "
            + "  gammastep -O $K >/dev/null 2>&1 & "
            + "fi",
            "sh", String(temp)]);
        settle.restart();
    }

    Timer { id: applyTimer; interval: 250; onTriggered: root._apply() }
    Timer { id: settle; interval: 500; onTriggered: root.refresh() }

    function refresh() { runningProc.running = true; }
    Process {
        id: runningProc
        command: ["sh", "-c",
            "if pgrep -x wlsunset >/dev/null || pgrep -x gammastep >/dev/null; then echo on; else echo off; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim() === "on"
        }
    }

    FileView {
        id: file
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                const o = JSON.parse(text() || "{}");
                if (o.temp) root.temp = o.temp;
            } catch (e) {}
        }
    }
    Process { id: saveProc }
    function _save() {
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.statePath, JSON.stringify({ temp: root.temp })];
        saveProc.running = true;
    }

    Component.onCompleted: { file.reload(); refresh(); }
}
