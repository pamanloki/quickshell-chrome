pragma Singleton

import Quickshell
import QtQuick

/**
 * Session power actions. Uses loginctl (elogind on Void) for suspend / reboot /
 * poweroff, niri for sign-out, and swaylock (falling back to loginctl
 * lock-session) for locking. Destructive actions are confirmed by the UI
 * (PowerMenu) before calling these.
 */
Singleton {
    id: root

    function lock() {
        Quickshell.execDetached(["sh", "-c",
            "command -v swaylock >/dev/null 2>&1 && exec swaylock -f; "
            + "command -v gtklock  >/dev/null 2>&1 && exec gtklock -d; "
            + "command -v waylock  >/dev/null 2>&1 && exec waylock; "
            + "command -v hyprlock >/dev/null 2>&1 && exec hyprlock; "
            + "loginctl lock-session"]);
    }

    function logout() {
        Quickshell.execDetached(["sh", "-c",
            "niri msg action quit --skip-confirmation 2>/dev/null "
            + "|| loginctl terminate-session \"${XDG_SESSION_ID:-}\""]);
    }

    function suspend() {
        Quickshell.execDetached(["sh", "-c", "loginctl suspend || zzz"]);
    }

    function reboot() {
        Quickshell.execDetached(["sh", "-c", "loginctl reboot"]);
    }

    function poweroff() {
        Quickshell.execDetached(["sh", "-c", "loginctl poweroff"]);
    }

    // Actions for the PowerMenu; `confirm` marks the destructive ones.
    readonly property var actions: [
        { id: "lock",     label: "Lock",      icon: "lock",                 confirm: false },
        { id: "suspend",  label: "Sleep",     icon: "bedtime",              confirm: false },
        { id: "logout",   label: "Sign out",  icon: "logout",               confirm: true  },
        { id: "reboot",   label: "Restart",   icon: "restart_alt",          confirm: true  },
        { id: "poweroff", label: "Power off", icon: "power_settings_new",   confirm: true  }
    ]

    function run(id) {
        if (id === "lock") lock();
        else if (id === "suspend") suspend();
        else if (id === "logout") logout();
        else if (id === "reboot") reboot();
        else if (id === "poweroff") poweroff();
    }
}
