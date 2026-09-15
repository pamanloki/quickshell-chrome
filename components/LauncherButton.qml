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
    readonly property bool active: State.launcherOpen

    Rectangle {
        id: circle
        anchors.centerIn: parent
        width: 34
        height: 34
        radius: width / 2
        color: root.active ? Theme.accent : "#f1f3f4"
        scale: press.pressed ? 0.9 : (hover.hovered ? 1.06 : 1.0)

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on scale { NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic } }

        // Central Google-blue dot
        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 12
            radius: width / 2
            color: root.active ? "#ffffff" : Theme.accent
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        id: press
        onTapped: {
            State.activeScreen = root.targetScreen;
            State.toggleLauncher();
        }
    }
}
