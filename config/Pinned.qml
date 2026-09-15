pragma Singleton

import Quickshell
import QtQuick

/**
 * Apps pinned to the shelf, ChromeOS style. Each entry is a desktop-entry id
 * (the .desktop filename without extension). Edit this list to taste — unknown
 * ids are skipped silently, and a fallback exec/icon lets you pin things that
 * don't ship a .desktop file.
 */
Singleton {
    id: root

    // Ordered list. `id` is matched against DesktopEntries; `exec`/`icon`/`name`
    // are optional overrides / fallbacks.
    readonly property var apps: [
        { id: "google-chrome",        exec: "google-chrome-stable", icon: "google-chrome",     name: "Chrome" },
        { id: "org.gnome.Nautilus",   exec: "nautilus",             icon: "system-file-manager", name: "Files" },
        { id: "org.gnome.gedit",      exec: "gedit",                icon: "text-editor",       name: "Text" },
        { id: "org.gnome.Calculator", exec: "gnome-calculator",     icon: "accessories-calculator", name: "Calculator" },
        { id: "code",                 exec: "code",                 icon: "vscode",            name: "Code" },
        { id: "org.gnome.Terminal",   exec: "gnome-terminal",       icon: "utilities-terminal", name: "Terminal" },
        { id: "org.gnome.Settings",   exec: "gnome-control-center", icon: "preferences-system", name: "Settings" }
    ]
}
