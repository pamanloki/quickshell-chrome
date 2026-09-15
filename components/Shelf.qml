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

    // ── Find a running window that belongs to a pinned app ──────────────────
    function toplevelFor(app) {
        const key = ((app.id || app.exec || "") + "").toLowerCase();
        if (!key)
            return null;
        const short = key.split(".").pop();
        const list = ToplevelManager.toplevels?.values ?? [];
        for (const t of list) {
            const a = (t.appId || "").toLowerCase();
            if (!a)
                continue;
            if (a === key || a === short || a.indexOf(short) !== -1 || key.indexOf(a) !== -1)
                return t;
        }
        return null;
    }

    function launch(app) {
        const running = toplevelFor(app);
        if (running) {
            if (running.activated)
                return;       // already focused
            running.activate();
            return;
        }
        Apps.exec(app);
    }

    // Running windows that don't belong to any pinned app — shown as extra
    // dock icons (ChromeOS/dock behaviour: pinned kept, running added).
    function runningUnpinned() {
        const list = ToplevelManager.toplevels?.values ?? [];
        const res = [];
        for (const t of list) {
            let isPinned = false;
            for (const app of Pinned.apps) {
                if (toplevelFor(app) === t) { isPinned = true; break; }
            }
            if (!isPinned)
                res.push(t);
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

    // Launcher — far left
    LauncherButton {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.gapLarge
        targetScreen: shelf.modelData
    }

    // Pinned + running apps — centered
    RowLayout {
        anchors.centerIn: parent
        spacing: 4

        // Pinned apps (kept), with a running dot when a window matches.
        Repeater {
            model: Pinned.apps
            delegate: ShelfApp {
                required property var modelData
                appData: modelData
                property var tl: shelf.toplevelFor(modelData)
                running: tl !== null
                focused: tl?.activated ?? false
                onActivated: shelf.launch(modelData)
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
            visible: shelf.runningUnpinned().length > 0
        }

        // Running apps that aren't pinned.
        Repeater {
            model: shelf.runningUnpinned()
            delegate: ShelfApp {
                required property var modelData   // a Toplevel
                appData: ({
                    id: modelData.appId,
                    name: (modelData.title && modelData.title.length ? modelData.title : modelData.appId),
                    icon: modelData.appId
                })
                running: true
                focused: modelData.activated
                onActivated: modelData.activate()
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
