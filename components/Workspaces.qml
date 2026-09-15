import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

/**
 * niri workspace pips on the shelf. The active workspace is a wide accent pill;
 * click a pip to switch. Hidden when not on niri or with no workspaces.
 */
RowLayout {
    id: root
    spacing: 6
    visible: Niri.onNiri && Niri.workspaces.length > 0

    Repeater {
        model: Niri.workspaces
        delegate: Rectangle {
            required property var modelData
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: modelData.is_active ? 24 : 10
            implicitHeight: 10
            radius: 5
            color: modelData.is_active ? Theme.accent
                 : (modelData.is_urgent ? Theme.bad
                 : (pipMa.containsMouse ? Theme.text : Theme.textFaint))

            Behavior on implicitWidth { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            MouseArea {
                id: pipMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(modelData.idx)
            }
        }
    }
}
