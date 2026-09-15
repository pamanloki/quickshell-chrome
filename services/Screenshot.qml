pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

/**
 * Screenshots via grim (+ slurp for region). Four modes — region/full ×
 * clipboard/file — with the chosen mode remembered. File shots go to
 * ~/Pictures/Screenshots and are also copied; clipboard shots only copy.
 */
Singleton {
    id: root

    // "region-file" | "region-clip" | "full-file" | "full-clip"
    property string mode: "region-file"

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property string statePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshell-chrome/screenshot"

    readonly property var modes: [
        { id: "region-file", label: "Region → File",      icon: "screenshot_region" },
        { id: "region-clip", label: "Region → Clipboard", icon: "content_copy" },
        { id: "full-file",   label: "Full → File",        icon: "fullscreen" },
        { id: "full-clip",   label: "Full → Clipboard",   icon: "content_copy" }
    ]

    function labelOf(m) {
        for (const e of modes) if (e.id === m) return e.label;
        return m;
    }
    readonly property string modeLabel: labelOf(mode)

    function setMode(m) {
        mode = m;
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.statePath, m];
        saveProc.running = true;
    }

    // Capture using a given mode (defaults to the remembered one).
    function capture(m) {
        const use = m || root.mode;
        const region = use.indexOf("region") === 0;
        const clip = use.indexOf("clip") !== -1;
        const geom = region ? "-g \"$(slurp)\"" : "";
        let inner;
        if (clip)
            inner = "grim " + geom + " - | wl-copy && fyi 'Screenshot' 'Copied to clipboard'";
        else
            inner = "f=\"$d/shot-$(date +%Y%m%d-%H%M%S).png\"; grim " + geom + " \"$f\" && "
                  + "{ command -v wl-copy >/dev/null 2>&1 && wl-copy < \"$f\"; fyi -i \"$f\" 'Screenshot' \"Saved to $f\"; }";
        Quickshell.execDetached(["sh", "-c", "d=\"$1\"; mkdir -p \"$d\"; sleep 0.2; " + inner, "sh", root.dir]);
        if (!clip)
            Tote.scheduleRefresh();
    }

    // Pick a mode and capture with it right away.
    function pickAndCapture(m) { setMode(m); capture(m); }

    FileView {
        id: file
        path: root.statePath
        printErrors: false
        onLoaded: { const t = text().trim(); if (t) root.mode = t; }
    }
    Component.onCompleted: file.reload()
}
