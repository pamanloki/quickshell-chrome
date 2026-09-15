pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

/**
 * Desktop notification server. Feeds transient toasts (`list`) and keeps a
 * persistent history for the notification center. Do-Not-Disturb suppresses
 * toasts but still logs to history.
 */
Singleton {
    id: root

    readonly property var list: server.trackedNotifications
    property bool doNotDisturb: false

    property var history: []
    property int unread: 0
    property int _seq: 0
    readonly property int maxHistory: 50

    function _push(n) {
        const entry = {
            id: ++root._seq,
            appName: n.appName || "Notification",
            desktopEntry: n.desktopEntry || "",
            summary: n.summary || "",
            body: n.body || "",
            appIcon: n.appIcon || "",
            image: n.image || "",
            time: Date.now()
        };
        const h = root.history.slice();
        h.unshift(entry);
        if (h.length > root.maxHistory)
            h.length = root.maxHistory;
        root.history = h;
        root.unread = root.unread + 1;
    }

    function clearHistory() { root.history = []; root.unread = 0; }
    function removeHistory(id) { root.history = root.history.filter(e => e.id !== id); }
    function markRead() { root.unread = 0; }

    // ── Per-app badges (shelf icons) ────────────────────────────────────────
    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    function _matches(e, idNorm, nameNorm) {
        const de = _norm(e.desktopEntry);
        const an = _norm(e.appName);
        return (de && (de === idNorm || de === nameNorm))
            || (an && (an === idNorm || an === nameNorm));
    }

    // How many notifications in history belong to a given app.
    function countFor(idNorm, nameNorm) {
        let c = 0;
        for (const e of root.history)
            if (_matches(e, idNorm, nameNorm))
                c++;
        return c;
    }

    // Drop an app's notifications (e.g. when its window is opened / focused).
    function clearFor(idNorm, nameNorm) {
        const keep = root.history.filter(e => !_matches(e, idNorm, nameNorm));
        const removed = root.history.length - keep.length;
        if (removed <= 0)
            return;
        root.history = keep;
        root.unread = Math.max(0, root.unread - removed);
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: notification => {
            root._push(notification);
            if (root.doNotDisturb) {
                notification.expire();
                return;
            }
            notification.tracked = true;
        }
    }
}
