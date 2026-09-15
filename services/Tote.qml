pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * ChromeOS "Tote" / holding space backend: tracks the most recent screenshots
 * so they can be re-opened, copied, or discarded straight from the shelf. The
 * tote button only appears while there is something to show, mirroring the way
 * ChromeOS surfaces holding space on demand.
 */
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    // Absolute paths, newest first (capped).
    property var recent: []
    readonly property bool hasItems: recent.length > 0

    function refresh() {
        lister.running = false;
        lister.running = true;
    }

    // Screenshots are written by a detached process, so give the file a moment
    // to land on disk before we re-list.
    function scheduleRefresh() { settle.restart(); }
    Timer { id: settle; interval: 500; repeat: false; onTriggered: root.refresh() }

    Process {
        id: lister
        command: ["sh", "-c",
            "ls -t \"$1\"/*.png \"$1\"/*.jpg \"$1\"/*.jpeg 2>/dev/null | head -n 8",
            "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.recent = text.split("\n")
                    .map(s => s.trim())
                    .filter(s => s.length > 0);
            }
        }
    }

    function baseName(path) {
        const i = path.lastIndexOf("/");
        return i >= 0 ? path.slice(i + 1) : path;
    }

    function open(path) { Quickshell.execDetached(["xdg-open", path]); }
    function copy(path) { Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"", "sh", path]); }
    function reveal() { Quickshell.execDetached(["xdg-open", root.dir]); }

    Process {
        id: rmProc
        onExited: root.refresh()
    }
    function remove(path) {
        rmProc.command = ["rm", "-f", path];
        rmProc.running = true;
    }

    Component.onCompleted: refresh()
}
