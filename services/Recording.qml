pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Screen recording via wf-recorder. On-demand only — a single recorder process
 * runs while recording and is stopped with SIGINT (which finalises the file),
 * so nothing runs in the background. Clips go to ~/Videos/Screencasts.
 */
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Videos/Screencasts"
    readonly property bool recording: recProc.running

    function start(region) {
        if (recProc.running)
            return;
        const inner = region
            ? "g=$(slurp) || exit 1; exec wf-recorder -g \"$g\" -f \"$f\""
            : "exec wf-recorder -f \"$f\"";
        recProc.command = ["sh", "-c",
            "d=\"$1\"; mkdir -p \"$d\"; f=\"$d/rec-$(date +%Y%m%d-%H%M%S).mp4\"; " + inner,
            "sh", root.dir];
        recProc.running = true;
    }

    function stop() {
        if (recProc.running)
            recProc.signal(2);   // SIGINT — wf-recorder finalises the file
    }

    function toggle(region) {
        if (recProc.running) stop();
        else start(region);
    }

    Process {
        id: recProc
        onExited: (code, status) => {
            if (code === 0 || code === 130)   // 130 = SIGINT (normal stop)
                Quickshell.execDetached(["fyi", "-i", "media-record",
                                         "Screen recording", "Saved to " + root.dir]);
        }
    }
}
