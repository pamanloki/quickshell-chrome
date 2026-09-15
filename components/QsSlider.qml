import QtQuick
import "root:/config"

/**
 * A ChromeOS quick-settings slider row: a leading icon overlaid on a rounded
 * track with a filled portion and a draggable knob. `value` is 0..1.
 */
Item {
    id: root

    property string icon: "brightness_medium"
    property real value: 0.5
    property bool iconClickable: false

    signal moved(real value)
    signal iconClicked()

    implicitHeight: 44

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHigh

        // Filled portion
        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            radius: height / 2
            width: Math.max(height, root.value * parent.width)
            color: Theme.accent
            Behavior on width {
                enabled: !drag.active
                NumberAnimation { duration: Theme.durFast }
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            property bool active: pressed
            function apply(mx) {
                const v = Math.max(0, Math.min(1, mx / width));
                root.value = v;
                root.moved(v);
            }
            onPressed: (m) => apply(m.x)
            onPositionChanged: (m) => { if (pressed) apply(m.x); }
        }

        // Leading icon (sits on the filled part, on top so it can be clicked)
        MaterialIcon {
            id: leadIcon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            size: 20
            fill: 1
            color: Theme.textOnAccent

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                enabled: root.iconClickable
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }
    }
}
