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
        State.activeScreen === null || State.activeScreen === modelData

    LazyLoader {
        active: State.launcherOpen && host.onThisScreen
        Launcher { screen: host.modelData }
    }

    LazyLoader {
        active: State.quickSettingsOpen && host.onThisScreen
        QuickSettings { screen: host.modelData }
    }
}
