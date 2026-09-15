import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * Dock right-click menu. Lists every open window of the app so you can pick or
 * close one (e.g. several `foot` terminals), plus "New window" and Add/Remove
 * from Dock. Created on demand by OverlayHost.
 */
PanelWindow {
    id: menu

    WlrLayershell.namespace: "quickshell:dockmenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    readonly property string appId: ShellState.dockMenuAppId
    readonly property string norm: _norm(appId)
    readonly property var windows: {
        const list = ToplevelManager.toplevels?.values ?? [];
        return list.filter(t => menu._norm(t.appId) === menu.norm);
    }
    readonly property var entry: Apps.byId(appId)
    readonly property string appLabel: entry?.name ?? appId

    function focus(t) { t.activate(); ShellState.closeAll(); }
    function newWindow() {
        ShellState.closeAll();
        if (entry) entry.execute();
        else if (appId) Quickshell.execDetached(["sh", "-c", appId]);
    }

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Rectangle {
        id: box
        width: 264
        height: menuCol.implicitHeight + 10
        radius: Theme.radius
        color: Theme.surfaceGlass
        border.width: 1
        border.color: Theme.outline

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.gap
        x: Math.max(Theme.gap,
                    Math.min(ShellState.dockMenuX - width / 2,
                             parent.width - width - Theme.gap))

        transformOrigin: Item.Bottom
        Component.onCompleted: { scale = 0.94; opacity = 0; anim.start(); }
        ParallelAnimation {
            id: anim
            NumberAnimation { target: box; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
            NumberAnimation { target: box; property: "opacity"; to: 1; duration: Theme.durNormal }
        }

        MouseArea { anchors.fill: parent }

        Column {
            id: menuCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 5
            spacing: 1

            // App name + window count
            Item {
                width: parent.width
                height: menu.windows.length > 0 ? 24 : 0
                visible: menu.windows.length > 0
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.appLabel + " · " + menu.windows.length
                        + (menu.windows.length > 1 ? " windows" : " window")
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width - 16
                }
            }

            // Window rows
            Repeater {
                model: menu.windows
                delegate: Rectangle {
                    required property var modelData     // Toplevel
                    width: menuCol.width
                    height: 36
                    radius: Theme.radiusSmall
                    color: rowMa.containsMouse ? Theme.hover : "transparent"

                    MaterialIcon {
                        id: dot
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        icon: modelData.activated ? "radio_button_checked" : "radio_button_unchecked"
                        size: 16
                        color: modelData.activated ? Theme.accent : Theme.textDim
                    }
                    Text {
                        anchors.left: dot.right
                        anchors.leftMargin: 8
                        anchors.right: closeBtn.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: (modelData.title && modelData.title.length) ? modelData.title : menu.appLabel
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        id: closeBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26; height: 26; radius: 13
                        color: closeMa.containsMouse ? Theme.surfaceHigh : "transparent"
                        MaterialIcon { anchors.centerIn: parent; icon: "close"; size: 15; color: Theme.textDim }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.close()
                        }
                    }
                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        anchors.rightMargin: 32
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menu.focus(modelData)
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width - 8
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                color: Theme.outline
                visible: menu.windows.length > 0
            }

            // New window
            MenuItem {
                icon: "add"
                label: "New window"
                visible: menu.entry !== null || menu.appId.length > 0
                onTriggered: menu.newWindow()
            }

            // Add / Remove from Dock
            MenuItem {
                icon: ShellState.dockMenuPinned ? "keep_off" : "keep"
                label: ShellState.dockMenuPinned ? "Remove from Dock" : "Add to Dock"
                onTriggered: {
                    if (ShellState.dockMenuPinned) DockConfig.unpin(menu.appId);
                    else DockConfig.pin(menu.appId);
                    ShellState.closeAll();
                }
            }
        }
    }

    component MenuItem: Rectangle {
        property string icon: ""
        property string label: ""
        signal triggered()
        width: menuCol ? menuCol.width : 0
        height: visible ? 36 : 0
        radius: Theme.radiusSmall
        color: miMa.containsMouse ? Theme.hover : "transparent"

        MaterialIcon {
            id: miIcon
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            icon: parent.icon
            size: 18
            color: Theme.text
        }
        Text {
            anchors.left: miIcon.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }
        MouseArea {
            id: miMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }
}
