pragma Singleton

import Quickshell
import QtQuick

/**
 * Screenshots via grim (+ slurp for region). Saves to ~/Pictures/Screenshots,
 * copies to the clipboard with wl-copy, and notifies. Overlays are closed first
 * so a region selection isn't blocked.
 */
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    function _shot(grimArgs) {
        Quickshell.execDetached(["sh", "-c",
              "d=\"$1\"; mkdir -p \"$d\"; f=\"$d/shot-$(date +%Y%m%d-%H%M%S).png\"; "
            + "sleep 0.2; "
            + "if grim " + grimArgs + " \"$f\"; then "
            + "  command -v wl-copy >/dev/null 2>&1 && wl-copy < \"$f\"; "
            + "  notify-send -i \"$f\" 'Screenshot' \"Saved to $f\"; "
            + "fi",
            "sh", root.dir]);
    }

    function region() { _shot("-g \"$(slurp)\""); }
    function full()   { _shot(""); }
}
