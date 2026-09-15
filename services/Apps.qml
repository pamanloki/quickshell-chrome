pragma Singleton

import Quickshell
import QtQuick

/** Safe wrappers around DesktopEntries so a missing id never throws. */
Singleton {
    id: root

    function byId(id) {
        if (!id)
            return null;
        try {
            return DesktopEntries.byId(id) ?? null;
        } catch (e) {
            return null;
        }
    }

    function exec(app) {
        const entry = byId(app.id);
        if (entry) {
            entry.execute();
            return true;
        }
        if (app.exec) {
            Quickshell.execDetached(["sh", "-c", app.exec]);
            return true;
        }
        return false;
    }
}
