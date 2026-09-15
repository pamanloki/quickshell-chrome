import QtQuick
import "root:/config"

/** Small circular icon button used in the quick-settings header row. */
Item {
    id: root
    property string icon: "settings"
    property int diameter: 40
    property color iconColor: Theme.text
    signal clicked()

    implicitWidth: diameter
    implicitHeight: diameter

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: width / 2
        color: Theme.surfaceHigh

        MaterialIcon {
            anchors.centerIn: parent
            icon: root.icon
            size: Math.round(root.diameter * 0.5)
            color: root.iconColor
        }

        StateLayer {
            radius: bg.radius
            onClicked: root.clicked()
        }
    }
}
