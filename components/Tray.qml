import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "root:/config"

/**
 * System tray (StatusNotifierItem host) in the shelf status area. Left-click
 * activates an item, right-click opens its menu (or secondary-activates when it
 * has none), middle-click secondary-activates.
 */
RowLayout {
    id: tray
    property var targetScreen: null
    spacing: 2

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: tItem
            required property var modelData
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 26
            implicitHeight: Theme.iconSize

            Rectangle {
                anchors.centerIn: parent
                width: 26; height: 26; radius: Theme.radiusSmall
                color: tMa.containsMouse ? Theme.hover : "transparent"
                Image {
                    anchors.centerIn: parent
                    width: 18; height: 18
                    source: tItem.modelData.icon
                    sourceSize.width: 36
                    sourceSize.height: 36
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                }
            }

            MouseArea {
                id: tMa
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (m) => {
                    if (m.button === Qt.LeftButton) {
                        tItem.modelData.activate();
                    } else if (m.button === Qt.MiddleButton) {
                        tItem.modelData.secondaryActivate();
                    } else {
                        if (tItem.modelData.hasMenu && tItem.modelData.menu) {
                            const gx = tItem.mapToItem(null, tItem.width / 2, 0).x;
                            ShellState.openTrayMenu(tItem.modelData.menu, gx, tray.targetScreen);
                        } else {
                            tItem.modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
