import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/config"
import "root:/services"

/**
 * A single pinned app tile on the shelf: rounded icon, hover pill, running
 * indicator dot underneath, and a tooltip. `appData` is one entry from the
 * Pinned config; `running` and `focused` come from the shelf's toplevel match.
 */
Item {
    id: root

    property var appData
    property bool running: false
    property bool focused: false

    signal activated()

    readonly property var entry: Apps.byId(appData?.id)
    readonly property string appName: entry?.name ?? appData?.name ?? appData?.id ?? "App"
    readonly property string iconName: entry?.icon ?? appData?.icon ?? "application-x-executable"

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

        StateLayer {
            radius: pill.radius
            onClicked: root.activated()
        }
    }

    // Running indicator (ChromeOS shows a short bar/dot below the icon)
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -2
        width: root.focused ? 16 : 6
        height: 3
        radius: 2
        visible: root.running
        color: root.focused ? Theme.accent : Theme.textDim
        Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.durNormal } }
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
