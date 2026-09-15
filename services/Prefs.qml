pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/** Persisted user preferences for the shell. */
Singleton {
    id: root

    property bool shelfAutoHide: false

    readonly property string statePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshell-chrome/prefs.json"

    function _save() {
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.statePath, JSON.stringify({ shelfAutoHide: root.shelfAutoHide })];
        saveProc.running = true;
    }

    function setShelfAutoHide(v) { root.shelfAutoHide = v; _save(); }
    function toggleShelfAutoHide() { setShelfAutoHide(!root.shelfAutoHide); }

    FileView {
        id: file
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                const o = JSON.parse(text() || "{}");
                if (typeof o.shelfAutoHide === "boolean")
                    root.shelfAutoHide = o.shelfAutoHide;
            } catch (e) {}
        }
    }
    Process { id: saveProc }
    Component.onCompleted: file.reload()
}
