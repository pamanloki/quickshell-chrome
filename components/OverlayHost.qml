import Quickshell
import "root:/config"

/**
 * Per-screen host for the on-demand overlays (launcher + quick settings).
 * Each overlay window is created lazily only while it is open and on the active
 * screen, and destroyed the moment it closes — so a closed overlay can never
 * leave a full-screen layer surface capturing input.
 */
Scope {
    id: host
    required property var modelData

    readonly property bool onThisScreen:
        ShellState.activeScreen === null || ShellState.activeScreen === modelData

    LazyLoader {
        active: ShellState.launcherOpen && host.onThisScreen
        Launcher { screen: host.modelData }
    }

    LazyLoader {
        active: ShellState.quickSettingsOpen && host.onThisScreen
        QuickSettings { screen: host.modelData }
    }

    LazyLoader {
        active: ShellState.dockMenuOpen && host.onThisScreen
        DockMenu { screen: host.modelData }
    }

    LazyLoader {
        active: ShellState.calendarOpen && host.onThisScreen
        Calendar { screen: host.modelData }
    }

    LazyLoader {
        active: ShellState.notificationsOpen && host.onThisScreen
        NotificationCenter { screen: host.modelData }
    }

    LazyLoader {
        active: ShellState.settingsOpen && host.onThisScreen
        Settings { screen: host.modelData }
    }
}
