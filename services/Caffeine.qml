pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Keep-awake toggle. While active, holds a systemd idle/sleep inhibitor so the
 * screen won't blank or the system suspend.
 */
Singleton {
    id: root

    property bool active: false
    function toggle() { active = !active; }

    Process {
        id: inhibit
        running: root.active
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=quickshell-chrome",
                  "--why=Caffeine", "sleep", "infinity"]
    }
}
