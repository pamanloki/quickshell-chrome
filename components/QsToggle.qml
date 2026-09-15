import QtQuick
import "root:/config"

/**
 * A ChromeOS quick-settings feature pod: a rounded rectangle with a circular
 * icon badge, a title and a subtitle. Turns accent-colored when `active`.
 * Clicking the main body fires `toggled`; the trailing chevron (when
 * `hasDetail`) fires `detail` for the sub-page.
 */
Item {
    id: root

    property string icon: "wifi"
    property string title: "Wi-Fi"
    property string subtitle: ""
    property bool active: false
    property bool hasDetail: false

    signal toggled()
    signal detail()

    implicitHeight: 64

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radius
        color: root.active ? Theme.accent : Theme.surfaceHigh
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: width / 2
                color: root.active ? Qt.rgba(1, 1, 1, 0.22) : Theme.surface
                MaterialIcon {
                    anchors.centerIn: parent
                    icon: root.icon
                    size: 20
                    fill: root.active ? 1 : 0
                    color: root.active ? Theme.onAccent : Theme.text
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40 - 10 - (root.hasDetail ? 24 : 0)
                spacing: 1
                Text {
                    text: root.title
                    color: root.active ? Theme.onAccent : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: root.subtitle
                    visible: root.subtitle.length > 0
                    color: root.active ? Qt.rgba(6/255, 46/255, 111/255, 0.75) : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        StateLayer {
            radius: bg.radius
            onClicked: root.toggled()
        }

        // Detail chevron (own hit target on top of the state layer)
        Rectangle {
            visible: root.hasDetail
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 6
            width: 32
            height: 32
            radius: width / 2
            color: "transparent"
            MaterialIcon {
                anchors.centerIn: parent
                icon: "chevron_right"
                size: 20
                color: root.active ? Theme.onAccent : Theme.textDim
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.detail()
            }
        }
    }
}
