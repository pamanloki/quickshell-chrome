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

    // Open with the first available image viewer, then the system default,
    // else notify — xdg-open often has no image handler on minimal setups.
    function open(path) {
        Quickshell.execDetached(["sh", "-c",
            "for c in imv swayimg nsxiv feh eog gwenview qimgv xdg-open; do "
            + "command -v \"$c\" >/dev/null 2>&1 && exec \"$c\" \"$1\"; done; "
            + "fyi 'Tote' 'No image viewer found (try: xbps-install imv)'",
            "sh", path]);
    }

    function copy(path) { Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"", "sh", path]); }

    // Open the screenshots folder in a file manager, else the default handler.
    function reveal() {
        Quickshell.execDetached(["sh", "-c",
            "for c in xdg-open nautilus thunar dolphin pcmanfm nemo; do "
            + "command -v \"$c\" >/dev/null 2>&1 && exec \"$c\" \"$1\"; done; "
            + "fyi 'Tote' 'No file manager found'",
            "sh", root.dir]);
    }

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
