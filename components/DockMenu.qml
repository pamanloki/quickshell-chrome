import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * Small right-click context menu for a dock icon: "Add to Dock" for a running
 * app that isn't pinned, or "Remove from Dock" for a pinned one. Full-screen
 * scrim closes it; created on demand by OverlayHost.
 */
PanelWindow {
    id: menu

    WlrLayershell.namespace: "quickshell:dockmenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Rectangle {
        id: box
        width: 210
        height: entry.height + 10
        radius: Theme.radiusSmall
        color: Theme.surfaceGlass
        border.width: 1
        border.color: Theme.outline

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.shelfHeight + Theme.gap
        x: Math.max(Theme.gap,
                    Math.min(ShellState.dockMenuX - width / 2,
                             parent.width - width - Theme.gap))

        MouseArea { anchors.fill: parent }   // swallow scrim clicks

        Rectangle {
            id: entry
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 5 }
            height: 38
            radius: Theme.radiusSmall
            color: ma.containsMouse ? Theme.hover : "transparent"

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                spacing: 10

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: ShellState.dockMenuPinned ? "keep_off" : "keep"
                    size: 18
                    color: Theme.text
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ShellState.dockMenuPinned ? "Remove from Dock" : "Add to Dock"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (ShellState.dockMenuPinned)
                        DockConfig.unpin(ShellState.dockMenuAppId);
                    else
                        DockConfig.pin(ShellState.dockMenuAppId);
                    ShellState.closeAll();
                }
            }
        }
    }
}
