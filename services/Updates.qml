pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Void Linux (xbps) update checker. Counts packages that would be updated
 * (dry-run, no root needed) and can launch the upgrade in a terminal.
 */
Singleton {
    id: root

    property int count: 0
    property bool checking: false
    property bool checked: false     // has a check completed at least once
    property bool syncing: false

    function refresh() {
        checking = true;
        checkProc.running = true;
    }

    function update() {
        Quickshell.execDetached(["sh", "-c",
              "cmd='sudo xbps-install -Su; echo; read -n1 -r -p \"Press any key to close…\"'; "
            + "for t in $TERMINAL footx foot alacritty kitty wezterm xterm; do "
            + "  command -v \"$t\" >/dev/null 2>&1 && exec \"$t\" -e sh -c \"$cmd\"; "
            + "done"]);
    }

    // Sync the repo index (needs root, so it runs in a terminal), then re-check.
    function syncAndCheck() {
        syncing = true;
        syncProc.command = ["sh", "-c",
              "cmd='sudo xbps-install -S'; "
            + "for t in $TERMINAL footx foot alacritty kitty wezterm xterm; do "
            + "  command -v \"$t\" >/dev/null 2>&1 && exec \"$t\" -e sh -c \"$cmd\"; "
            + "done"];
        syncProc.running = true;
    }

    Process {
        id: syncProc
        onExited: { root.syncing = false; settle.restart(); }
    }
    Timer { id: settle; interval: 1500; onTriggered: root.refresh() }

    Component.onCompleted: refresh()
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: root.refresh() }  // 30 min

    // Count only real update rows: xbps -n prints "<pkg-ver> update <arch> …"
    // per package, so match the "update" action word rather than every line.
    Process {
        id: checkProc
        command: ["sh", "-c", "xbps-install -Mun 2>/dev/null | grep -cw update || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: root.count = parseInt(text.trim()) || 0
        }
        onExited: { root.checking = false; root.checked = true; }
    }
}
