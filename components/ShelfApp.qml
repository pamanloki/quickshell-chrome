import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/config"
import "root:/services"

/**
 * A single app tile on the shelf: rounded icon with a hover pill, a running
 * indicator dot underneath and a tooltip. Pure ChromeOS look — no magnify,
 * bounce or scale animations, just a hover highlight. `appData` is {id,name,
 * icon}; `running`/`focused` come from the shelf's toplevel match.
 */
Item {
    id: root

    property var appData
    property bool running: false
    property bool focused: false

    signal activated()
    signal rightClicked(real screenX)

    readonly property var entry: Apps.byId(appData?.id)
    readonly property string appName: entry?.name ?? appData?.name ?? appData?.id ?? "App"
    readonly property string iconName: entry?.icon ?? appData?.icon ?? "application-x-executable"

    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }
    readonly property string _idNorm: _norm(appData?.id)
    readonly property string _nameNorm: _norm(appName)
    readonly property int notifCount: Notifications.countFor(_idNorm, _nameNorm)

    implicitWidth: Theme.iconSize + 8
    implicitHeight: Theme.iconSize + 8

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: Theme.iconSize
        height: Theme.iconSize
        radius: Theme.radiusSmall + 4
        color: "transparent"

        IconImage {
            id: img
            anchors.centerIn: parent
            width: parent.width - 12
            height: parent.height - 12
            source: Quickshell.iconPath(root.iconName, "application-x-executable")
            smooth: true
        }

        // Hover highlight + left click, no ripple (ChromeOS style).
        StateLayer {
            radius: pill.radius
            enableRipple: false
            onClicked: {
                Notifications.clearFor(root._idNorm, root._nameNorm);
                root.activated();
            }
        }

        // Right click → context menu (Add/Remove from Dock).
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: root.rightClicked(root.mapToItem(null, root.width / 2, 0).x)
        }
    }

    // Running indicator dot (no animation).
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -1
        width: root.focused ? 14 : 5
        height: 3
        radius: 1.5
        visible: root.running
        color: root.focused ? Theme.accent : Theme.textDim
    }

    // Notification badge (top-right of the icon).
    Rectangle {
        visible: root.notifCount > 0
        anchors.right: pill.right
        anchors.top: pill.top
        anchors.rightMargin: 4
        anchors.topMargin: 4
        width: root.notifCount > 1 ? Math.max(16, badgeText.implicitWidth + 8) : 12
        height: 12
        radius: 6
        color: Theme.bad
        border.width: 2
        border.color: Theme.shelf
        Text {
            id: badgeText
            anchors.centerIn: parent
            visible: root.notifCount > 1
            text: root.notifCount > 9 ? "9+" : root.notifCount
            color: "#ffffff"
            font.family: Theme.fontFamily
            font.pixelSize: 8
            font.weight: Font.Bold
        }
    }

    // Tooltip
    Loader {
        active: hover.hovered
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Theme.gap
        sourceComponent: Rectangle {
            width: label.implicitWidth + 20
            height: label.implicitHeight + 12
            radius: Theme.radiusSmall
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline
            Text {
                id: label
                anchors.centerIn: parent
                text: root.appName
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }
    }

    HoverHandler { id: hover }
}
