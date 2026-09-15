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

    // Dock right-click context menu.
    property bool dockMenuOpen: false
    property real dockMenuX: 0          // screen-x of the icon centre
    property string dockMenuAppId: ""
    property bool dockMenuPinned: false

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

    function closeAll() {
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        dockMenuOpen = false;
    }
}
