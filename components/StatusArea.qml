import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

/**
 * ChromeOS status area at the far right of the shelf. A single rounded pill
 * showing network / bluetooth / battery / clock. Click toggles Quick Settings.
 */
Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.iconSize

    property var targetScreen: null

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: Theme.radiusPill
        color: ShellState.quickSettingsOpen ? Theme.surfaceHigh : "transparent"
        implicitWidth: content.implicitWidth + 24

        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.gap

            MaterialIcon {
                icon: Bluetooth.icon
                size: 18
                color: Theme.text
                visible: Bluetooth.available && Bluetooth.powered
            }

            MaterialIcon {
                icon: Network.icon
                size: 18
                color: Theme.text
            }

            RowLayout {
                spacing: 4
                visible: Battery.available
                MaterialIcon {
                    icon: Battery.icon
                    size: 18
                    fill: 1
                    color: Battery.color
                }
                Text {
                    text: Battery.percent + "%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                width: 1
                height: 16
                color: Theme.outlineStrong
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: Time.time
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
            }
        }

        StateLayer {
            radius: pill.radius
            onClicked: {
                ShellState.activeScreen = root.targetScreen;
                ShellState.toggleQuickSettings();
            }
        }
    }
}
