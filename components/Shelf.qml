import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * The ChromeOS shelf: a translucent, full-width bar pinned to the bottom of a
 * screen. Launcher on the left, pinned/running apps centered, status area on
 * the right. Instantiated once per screen from shell.qml.
 */
PanelWindow {
    id: shelf
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:shelf"
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: Theme.shelfHeight
    exclusiveZone: Theme.shelfHeight
    color: "transparent"

    // ── App / window helpers (matched by normalized appId) ──────────────────
    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    function toplevelsOf(norm) {
        const list = ToplevelManager.toplevels?.values ?? [];
        return list.filter(t => shelf._norm(t.appId) === norm);
    }
    function isRunning(norm) { return toplevelsOf(norm).length > 0; }
    function isFocused(norm) { return toplevelsOf(norm).some(t => t.activated); }

    // Focus a running app's next window (or the first).
    function activateApp(norm) {
        const ts = toplevelsOf(norm);
        if (ts.length === 0)
            return;
        const unfocused = ts.find(t => !t.activated);
        (unfocused || ts[0]).activate();
    }

    // Launch a pinned app by id, or focus it if it's already running.
    function launchOrFocus(appId) {
        const n = _norm(appId);
        if (isRunning(n)) { activateApp(n); return; }
        const entry = Apps.byId(appId);
        if (entry)
            entry.execute();
        else
            Quickshell.execDetached(["sh", "-c", appId]);
    }

    // One entry per running app (deduped) that isn't pinned — extra dock icons.
    function runningUnpinned() {
        const list = ToplevelManager.toplevels?.values ?? [];
        const seen = ({});
        const res = [];
        for (const t of list) {
            const n = shelf._norm(t.appId);
            if (!n || seen[n])
                continue;
            seen[n] = true;
            if (DockConfig.isPinned(t.appId))
                continue;
            res.push({ appId: t.appId, norm: n });
        }
        return res;
    }

    // Shelf background
    Rectangle {
        anchors.fill: parent
        color: Theme.shelf

        // top hairline
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: Theme.outline
        }
    }

    // Launcher + workspaces — far left
    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.gapLarge
        spacing: Theme.gapLarge

        LauncherButton {
            Layout.alignment: Qt.AlignVCenter
            targetScreen: shelf.modelData
        }
        Workspaces { Layout.alignment: Qt.AlignVCenter }
    }

    // Pinned + running apps — centered
    RowLayout {
        anchors.centerIn: parent
        spacing: 4

        // Pinned apps (persisted), with a running dot when a window matches.
        Repeater {
            model: DockConfig.pinned
            delegate: ShelfApp {
                required property var modelData          // appId string
                readonly property string norm: shelf._norm(modelData)
                appData: ({ id: modelData, icon: modelData })
                running: shelf.isRunning(norm)
                focused: shelf.isFocused(norm)
                onActivated: shelf.launchOrFocus(modelData)
                onRightClicked: (x) => ShellState.openDockMenu(modelData, x, true, shelf.modelData)
            }
        }

        // Divider between pinned and running-only apps.
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            width: 1
            height: Theme.iconSize * 0.55
            color: Theme.outlineStrong
            visible: DockConfig.pinned.length > 0 && shelf.runningUnpinned().length > 0
        }

        // Running apps that aren't pinned (one icon per app).
        Repeater {
            model: shelf.runningUnpinned()
            delegate: ShelfApp {
                required property var modelData          // { appId, norm }
                appData: ({ id: modelData.appId, icon: modelData.appId })
                running: true
                focused: shelf.isFocused(modelData.norm)
                onActivated: shelf.activateApp(modelData.norm)
                onRightClicked: (x) => ShellState.openDockMenu(modelData.appId, x, false, shelf.modelData)
            }
        }
    }

    // Status area — far right
    StatusArea {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapLarge
        targetScreen: shelf.modelData
    }
}
