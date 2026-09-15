pragma Singleton

import Quickshell
import QtQuick

/**
 * Global, shell-wide UI state shared between all windows.
 * Only one overlay-style surface should be open at a time.
 */
Singleton {
    id: root

    property bool launcherOpen: false
    property bool quickSettingsOpen: false
    property bool calendarOpen: false
    property bool notificationsOpen: false
    property bool settingsOpen: false
    property bool toteOpen: false
    property bool musicOpen: false
    property bool clipboardOpen: false

    readonly property bool anyOpen: launcherOpen || quickSettingsOpen || calendarOpen
        || notificationsOpen || settingsOpen || toteOpen || musicOpen || clipboardOpen
        || dockMenuOpen || trayMenuOpen || shelfMenuOpen

    // Right-click menu on empty shelf space.
    property bool shelfMenuOpen: false
    property real shelfMenuX: 0

    function openShelfMenu(x, screen) {
        closeAll();
        shelfMenuX = x;
        activeScreen = screen;
        shelfMenuOpen = true;
    }

    // Dock right-click context menu.
    property bool dockMenuOpen: false
    property real dockMenuX: 0          // screen-x of the icon centre
    property string dockMenuAppId: ""
    property bool dockMenuPinned: false

    // System-tray item menu.
    property bool trayMenuOpen: false
    property real trayMenuX: 0
    property var trayMenuHandle: null

    function openTrayMenu(handle, x, screen) {
        closeAll();
        trayMenuHandle = handle;
        trayMenuX = x;
        activeScreen = screen;
        trayMenuOpen = true;
    }

    // On-screen display (volume / brightness), independent of the overlays.
    property string osdKind: ""      // "volume" | "brightness"
    property int osdValue: 0         // 0..100
    property bool osdMuted: false
    property bool osdVisible: false

    function showOsd(kind, value, muted) {
        osdKind = kind;
        osdValue = value;
        osdMuted = muted || false;
        osdVisible = true;
        osdTimer.restart();
    }
    Timer { id: osdTimer; interval: 1600; onTriggered: root.osdVisible = false }

    // Which screen the pointer / interaction last happened on. Used so popups
    // and the launcher show up on the active monitor only.
    property var activeScreen: null

    function openDockMenu(appId, x, pinned, screen) {
        closeAll();
        dockMenuAppId = appId;
        dockMenuX = x;
        dockMenuPinned = pinned;
        activeScreen = screen;
        dockMenuOpen = true;
    }

    function toggleLauncher() {
        const next = !launcherOpen;
        closeAll();
        launcherOpen = next;
    }

    function toggleQuickSettings() {
        const next = !quickSettingsOpen;
        closeAll();
        quickSettingsOpen = next;
    }

    function toggleCalendar() {
        const next = !calendarOpen;
        closeAll();
        calendarOpen = next;
    }

    function toggleNotifications() {
        const next = !notificationsOpen;
        closeAll();
        notificationsOpen = next;
    }

    function toggleTote() {
        const next = !toteOpen;
        closeAll();
        toteOpen = next;
    }

    function toggleMusic() {
        const next = !musicOpen;
        closeAll();
        musicOpen = next;
    }

    function toggleClipboard() {
        const next = !clipboardOpen;
        closeAll();
        clipboardOpen = next;
    }

    property string settingsSection: "wallpaper"

    function toggleSettings(sect) {
        const next = !settingsOpen;
        closeAll();
        if (next) {
            settingsSection = sect || "wallpaper";
            settingsOpen = true;
        }
    }

    function closeAll() {
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        notificationsOpen = false;
        settingsOpen = false;
        toteOpen = false;
        musicOpen = false;
        clipboardOpen = false;
        dockMenuOpen = false;
        trayMenuOpen = false;
        shelfMenuOpen = false;
    }
}
