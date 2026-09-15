import QtQuick
import "root:/config"

/**
 * The ChromeOS launcher / "Everything" button: a white circle with a blue dot.
 * Toggles the fullscreen launcher.
 */
Item {
    id: root
    implicitWidth: Theme.iconSize
    implicitHeight: Theme.iconSize

    property var targetScreen: null
    readonly property bool active: ShellState.launcherOpen

    Rectangle {
        id: circle
        anchors.centerIn: parent
        width: 34
        height: 34
        radius: width / 2
        // No scale/bounce animation — just a hover highlight (ChromeOS style).
        color: root.active ? Theme.accent
                           : (hover.hovered ? "#ffffff" : "#f1f3f4")

        // Central Google-blue dot
        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 12
            radius: width / 2
            color: root.active ? "#ffffff" : Theme.accent
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        id: press
        onTapped: {
            ShellState.activeScreen = root.targetScreen;
            ShellState.toggleLauncher();
        }
    }
}
