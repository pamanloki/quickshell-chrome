import QtQuick
import "root:/config"

/**
 * Material-style interaction surface: hover + press tint plus an expanding
 * ripple on click. Drop it as the child of any clickable rounded container and
 * wire `onClicked`. It fills its parent and matches its parent's radius.
 */
MouseArea {
    id: root

    property int radius: Theme.radius
    property color color: Theme.rippleColor
    property color hoverColor: Theme.hover
    property color pressColor: Theme.press
    property bool enableRipple: true

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    // Hover / press tint
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.pressed ? root.pressColor : (root.containsMouse ? root.hoverColor : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    // Ripple
    Item {
        anchors.fill: parent
        clip: true
        visible: root.enableRipple

        Rectangle {
            id: ripple
            radius: width / 2
            color: root.color
            opacity: 0
            width: 0
            height: width
            transformOrigin: Item.Center

            property real endSize: Math.max(root.width, root.height) * 2.2
        }
    }

    onPressed: (mouse) => {
        if (!enableRipple)
            return;
        ripple.x = mouse.x - ripple.width / 2;
        ripple.y = mouse.y - ripple.height / 2;
        rippleAnim.restart();
    }

    ParallelAnimation {
        id: rippleAnim
        NumberAnimation {
            target: ripple
            property: "width"
            from: 0
            to: ripple.endSize
            duration: Theme.durSlow
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: ripple
            property: "x"
            to: root.width / 2 - ripple.endSize / 2
            duration: Theme.durSlow
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: ripple
            property: "y"
            to: root.height / 2 - ripple.endSize / 2
            duration: Theme.durSlow
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            NumberAnimation { target: ripple; property: "opacity"; from: 0.6; to: 0.35; duration: Theme.durFast }
            NumberAnimation { target: ripple; property: "opacity"; to: 0; duration: Theme.durNormal }
        }
    }
}
