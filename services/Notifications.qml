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
