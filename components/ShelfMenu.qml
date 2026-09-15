import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * Right-click context menu on empty shelf space — the ChromeOS shelf menu.
 * Toggle shelf auto-hide, jump to the wallpaper picker, or open Settings.
 * Created on demand by OverlayHost, positioned at the cursor.
 */
PanelWindow {
    id: menu

    WlrLayershell.namespace: "quickshell:shelfmenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Rectangle {
        id: box
        width: 240
        height: menuCol.implicitHeight + 10
        radius: Theme.radius
        color: Theme.surfaceGlass
        border.width: 1
        border.color: Theme.outline

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.gap
        x: Math.max(Theme.gap,
                    Math.min(ShellState.shelfMenuX - width / 2,
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

            MenuItem {
                icon: Prefs.shelfAutoHide ? "check_box" : "check_box_outline_blank"
                label: "Autohide shelf"
                onTriggered: { Prefs.toggleShelfAutoHide(); ShellState.closeAll(); }
            }
            MenuItem {
                icon: "wallpaper"
                label: "Change wallpaper"
                onTriggered: ShellState.toggleSettings("wallpaper")
            }
            MenuItem {
                icon: "palette"
                label: "Theme"
                onTriggered: ShellState.toggleSettings("theme")
            }

            Rectangle {
                width: parent.width - 8
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                color: Theme.outline
            }

            MenuItem {
                icon: "settings"
                label: "Settings"
                onTriggered: ShellState.toggleSettings("wallpaper")
            }
        }
    }

    component MenuItem: Rectangle {
        property string icon: ""
        property string label: ""
        signal triggered()
        width: menuCol ? menuCol.width : 0
        height: 36
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
