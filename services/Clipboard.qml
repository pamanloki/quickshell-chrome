pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Clipboard history backed by `cliphist` (ChromeOS-style Search+V). Requires a
 * running watcher, e.g. in your niri config:
 *
 *   spawn-at-startup "sh" "-c" "wl-paste --watch cliphist store"
 *
 * Entries are read from `cliphist list`; clicking one decodes it back onto the
 * clipboard so you can paste it with Ctrl+V.
 */
Singleton {
    id: root

    // [{ id: "123", preview: "copied text" }], newest first.
    property var entries: []
    property bool ready: false

    function refresh() {
        lister.running = false;
        lister.running = true;
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                const lines = text.split("\n");
                for (const line of lines) {
                    if (!line)
                        continue;
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    out.push({ id: line.slice(0, tab), preview: line.slice(tab + 1) });
                    if (out.length >= 50)
                        break;
                }
                root.entries = out;
                root.ready = true;
            }
        }
        onExited: (code) => { if (code !== 0) { root.entries = []; root.ready = true; } }
    }

    // Decode the matching entry back onto the clipboard (user then pastes).
    function use(id) {
        Quickshell.execDetached(["sh", "-c",
            "cliphist list | awk -v i=\"$1\" 'index($0,i\"\\t\")==1' "
            + "| cliphist decode | wl-copy",
            "sh", id]);
    }

    function remove(id) {
        rmProc.command = ["sh", "-c",
            "cliphist list | awk -v i=\"$1\" 'index($0,i\"\\t\")==1' | cliphist delete",
            "sh", id];
        rmProc.running = true;
    }
    Process { id: rmProc; onExited: root.refresh() }

    function clear() { wipeProc.running = true; }
    Process { id: wipeProc; command: ["cliphist", "wipe"]; onExited: root.refresh() }
}
