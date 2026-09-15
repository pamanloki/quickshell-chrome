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

    // "constant" holds `temp` all day; "schedule" ramps to `temp` at sunset and
    // back to daylight at sunrise (via wlsunset's own scheduling).
    property string mode: "constant"
    property string sunrise: "06:30"
    property string sunset: "18:30"

    function setMode(m) { mode = m; _save(); if (active) _apply(); }
    function _shift(t, deltaMin) {
        const p = (t || "00:00").split(":");
        let mins = ((parseInt(p[0]) || 0) * 60 + (parseInt(p[1]) || 0) + deltaMin + 1440) % 1440;
        const h = Math.floor(mins / 60), m = mins % 60;
        return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m);
    }
    function shiftSunset(d)  { sunset = _shift(sunset, d);   _save(); if (active) _apply(); }
    function shiftSunrise(d) { sunrise = _shift(sunrise, d); _save(); if (active) _apply(); }

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
        if (mode === "schedule") {
            // Ramp to `temp` at sunset, back to daylight at sunrise.
            Quickshell.execDetached(["sh", "-c",
                  "K=$1; D=$2; SR=$3; SS=$4; pkill -x wlsunset 2>/dev/null; pkill -x gammastep 2>/dev/null; "
                + "if command -v wlsunset >/dev/null 2>&1; then "
                + "  wlsunset -T $D -t $K -S \"$SR\" -s \"$SS\" >/dev/null 2>&1 & "
                + "elif command -v gammastep >/dev/null 2>&1; then "
                + "  gammastep -O $K >/dev/null 2>&1 & "
                + "fi",
                "sh", String(temp), String(maxTemp), sunrise, sunset]);
        } else {
            // Constant: day = K+1, night = K, with a 1-minute "day" window.
            Quickshell.execDetached(["sh", "-c",
                  "K=$1; pkill -x wlsunset 2>/dev/null; pkill -x gammastep 2>/dev/null; "
                + "if command -v wlsunset >/dev/null 2>&1; then "
                + "  wlsunset -T $((K+1)) -t $K -S 00:00 -s 00:01 >/dev/null 2>&1 & "
                + "elif command -v gammastep >/dev/null 2>&1; then "
                + "  gammastep -O $K >/dev/null 2>&1 & "
                + "fi",
                "sh", String(temp)]);
        }
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
                if (o.mode) root.mode = o.mode;
                if (o.sunrise) root.sunrise = o.sunrise;
                if (o.sunset) root.sunset = o.sunset;
            } catch (e) {}
        }
    }
    Process { id: saveProc }
    function _save() {
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.statePath, JSON.stringify({ temp: root.temp, mode: root.mode, sunrise: root.sunrise, sunset: root.sunset })];
        saveProc.running = true;
    }

    Component.onCompleted: { file.reload(); refresh(); }
}
