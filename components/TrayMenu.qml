import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"

/**
 * Renders a system-tray item's real (DBus) menu via QsMenuOpener, above the
 * shelf at the item's x. Supports submenu drill-down, separators, disabled
 * entries and checkboxes. Created on demand by OverlayHost.
 */
PanelWindow {
    id: win

    WlrLayershell.namespace: "quickshell:traymenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    property var stack: ShellState.trayMenuHandle ? [ShellState.trayMenuHandle] : []
    readonly property var currentHandle: stack.length > 0 ? stack[stack.length - 1] : null

    QsMenuOpener { id: opener; menu: win.currentHandle }

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Rectangle {
        id: box
        width: 250
        height: menuCol.implicitHeight + 10
        radius: Theme.radius
        color: Theme.surfaceGlass
        border.width: 1
        border.color: Theme.outline

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.gap
        x: Math.max(Theme.gap, Math.min(ShellState.trayMenuX - width / 2, parent.width - width - Theme.gap))

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
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 5 }
            spacing: 1

            // Back row (in a submenu)
            Rectangle {
                width: parent.width
                height: 34
                radius: Theme.radiusSmall
                visible: win.stack.length > 1
                color: backMa.containsMouse ? Theme.hover : "transparent"
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    MaterialIcon { anchors.verticalCenter: parent.verticalCenter; icon: "chevron_left"; size: 18; color: Theme.text }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Back"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontBody }
                }
                MouseArea { id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.stack = win.stack.slice(0, win.stack.length - 1) }
            }

            Repeater {
                model: opener.children

                delegate: Item {
                    id: entry
                    required property var modelData
                    width: menuCol.width
                    implicitHeight: modelData.isSeparator ? 9 : 34

                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 8; anchors.rightMargin: 8
                        height: 1
                        color: Theme.outline
                    }

                    Rectangle {
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: itemMa.containsMouse && entry.modelData.enabled ? Theme.hover : "transparent"

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 12
                            anchors.right: chev.left; anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: (entry.modelData.checkState === Qt.Checked ? "✓  " : "") + (entry.modelData.text || "")
                            color: entry.modelData.enabled ? Theme.text : Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }
                        MaterialIcon {
                            id: chev
                            anchors.right: parent.right; anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: entry.modelData.hasChildren
                            icon: "chevron_right"; size: 18; color: Theme.textDim
                        }
                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: entry.modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (entry.modelData.hasChildren) {
                                    win.stack = win.stack.concat([entry.modelData]);
                                } else {
                                    entry.modelData.triggered();
                                    ShellState.closeAll();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
