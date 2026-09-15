pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Wallpaper picker. Lists images from a folder (default ~/Pictures/Wallpapers,
 * override with QUICKSHELL_WALLPAPERS) and applies one via swww, falling back to
 * swaybg. The choice is remembered so it survives a shell reload.
 */
Singleton {
    id: root

    property var walls: []
    property string current: ""

    readonly property string dir:
        Quickshell.env("QUICKSHELL_WALLPAPERS")
        || (Quickshell.env("HOME") + "/Pictures/Wallpapers")

    readonly property string statePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshell-chrome/wallpaper"

    function refresh() { listProc.running = true; }

    function apply(path) {
        root.current = path;
        Quickshell.execDetached(["sh", "-c",
              "p=\"$1\"; "
            + "if command -v swww >/dev/null 2>&1; then "
            + "  swww query >/dev/null 2>&1 || { swww-daemon >/dev/null 2>&1 & sleep 0.4; }; "
            + "  swww img \"$p\" --transition-type fade --transition-duration 1; "
            + "elif command -v swaybg >/dev/null 2>&1; then "
            + "  pkill -x swaybg 2>/dev/null; swaybg -i \"$p\" -m fill >/dev/null 2>&1 & "
            + "fi; "
            + "mkdir -p \"$(dirname \"$2\")\"; printf %s \"$p\" > \"$2\"",
            "sh", path, root.statePath]);
    }

    Process {
        id: listProc
        command: ["sh", "-c",
            "d=\"$1\"; [ -d \"$d\" ] && find \"$d\" -maxdepth 2 -type f "
          + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort",
            "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.walls = text.trim().split("\n").filter(x => x.length > 0)
        }
    }

    FileView {
        id: file
        path: root.statePath
        printErrors: false
        onLoaded: root.current = text().trim()
    }

    Component.onCompleted: { file.reload(); refresh(); }
}
