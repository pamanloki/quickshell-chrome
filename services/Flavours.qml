pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Base16 theme control via the `flavours` CLI. Lists installed schemes and
 * applies one; applying rewrites the colors file the Theme watches, so the
 * whole shell re-themes live. No-op (empty list) if `flavours` isn't installed.
 */
Singleton {
    id: root

    property var schemes: []      // [{ slug, name }]
    property string current: ""

    function title(s) {
        return (s || "").replace(/[-_]/g, " ").replace(/\b\w/g, c => c.toUpperCase());
    }

    function refresh() {
        listProc.running = true;
        curProc.running = true;
    }

    function apply(slug) {
        applyProc.command = ["sh", "-c", "flavours apply \"$1\"", "sh", slug];
        applyProc.running = true;
        root.current = slug;
    }

    function random() {
        Quickshell.execDetached(["sh", "-c", "flavours random 2>/dev/null"]);
        settle.restart();
    }

    Timer { id: settle; interval: 600; onTriggered: root.refresh() }

    Process {
        id: listProc
        command: ["sh", "-c", "flavours list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const slugs = text.trim().split(/\s+/).filter(x => x.length > 0);
                root.schemes = slugs.map(s => ({ slug: s, name: root.title(s) }));
            }
        }
    }

    Process {
        id: curProc
        command: ["sh", "-c", "flavours current 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.current = text.trim() }
    }

    Process { id: applyProc; onExited: settle.restart() }

    Component.onCompleted: refresh()
}
