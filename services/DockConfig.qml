pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Persisted list of apps pinned to the shelf. Stored as JSON so it survives
 * restarts. Managed at runtime via the dock right-click menu ("Add to Dock" /
 * "Remove from Dock"). Starts empty — the user builds their own dock.
 */
Singleton {
    id: root

    property var pinned: []

    readonly property string path:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshell-chrome/dock_pinned.json"

    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    function isPinned(appId) {
        const n = _norm(appId);
        return root.pinned.some(p => _norm(p) === n);
    }

    function pin(appId) {
        if (!appId || isPinned(appId))
            return;
        const a = root.pinned.slice();
        a.push(appId);
        root.pinned = a;
        _save();
    }

    function unpin(appId) {
        const n = _norm(appId);
        root.pinned = root.pinned.filter(p => _norm(p) !== n);
        _save();
    }

    // Shift a pinned app by delta positions (drag-free reordering).
    function move(appId, delta) {
        const n = _norm(appId);
        const a = root.pinned.slice();
        const i = a.findIndex(p => _norm(p) === n);
        if (i < 0)
            return;
        const j = Math.max(0, Math.min(a.length - 1, i + delta));
        if (j === i)
            return;
        const it = a.splice(i, 1)[0];
        a.splice(j, 0, it);
        root.pinned = a;
        _save();
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        onLoaded: {
            try {
                const a = JSON.parse(text() || "[]");
                if (Array.isArray(a))
                    root.pinned = a;
            } catch (e) {}
        }
    }
    Component.onCompleted: file.reload()

    Process { id: saveProc }
    function _save() {
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.path, JSON.stringify(root.pinned)];
        saveProc.running = true;
    }
}
