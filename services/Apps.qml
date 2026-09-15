pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Safe wrappers around DesktopEntries, plus a persisted launch-frequency tally
 * so the launcher can surface a "Frequent" row.
 */
Singleton {
    id: root

    property var counts: ({})     // desktop id -> launch count

    readonly property string statePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshell-chrome/app_usage.json"

    function byId(id) {
        if (!id)
            return null;
        try {
            const e = DesktopEntries.byId(id);
            if (e)
                return e;
        } catch (e) {}
        try {
            return DesktopEntries.heuristicLookup(id) ?? null;
        } catch (e) {}
        return null;
    }

    function exec(app) {
        const entry = byId(app.id);
        if (entry) {
            record(app.id);
            entry.execute();
            return true;
        }
        if (app.exec) {
            record(app.id || app.exec);
            Quickshell.execDetached(["sh", "-c", app.exec]);
            return true;
        }
        return false;
    }

    function record(id) {
        if (!id)
            return;
        const c = Object.assign({}, root.counts);
        c[id] = (c[id] || 0) + 1;
        root.counts = c;
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.statePath, JSON.stringify(c)];
        saveProc.running = true;
    }

    // Most-launched apps, most first.
    function frequent(n) {
        const arr = DesktopEntries.applications?.values ?? [];
        const scored = [];
        for (const a of arr) {
            if (!a || a.noDisplay)
                continue;
            const s = root.counts[a.id] || 0;
            if (s > 0)
                scored.push({ entry: a, score: s });
        }
        scored.sort((x, y) => y.score - x.score);
        return scored.slice(0, n || 6).map(s => s.entry);
    }

    FileView {
        id: file
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                const o = JSON.parse(text() || "{}");
                if (o && typeof o === "object")
                    root.counts = o;
            } catch (e) {}
        }
    }
    Process { id: saveProc }
    Component.onCompleted: file.reload()
}
