import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * ChromeOS "Tote" popup: recent screenshots as thumbnails, opened from the
 * shelf status area. Each tile can be opened, copied, or removed. Bottom-right
 * above the shelf; scrim / Esc closes.
 */
PanelWindow {
    id: tote

    WlrLayershell.namespace: "quickshell:tote"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Loader {
        active: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.gap

        sourceComponent: Rectangle {
            id: bubble
            width: 340
            implicitHeight: box.implicitHeight + 2 * Theme.gapLarge
            height: implicitHeight
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline

            transformOrigin: Item.BottomRight
            Component.onCompleted: { scale = 0.94; opacity = 0; anim.start(); }
            ParallelAnimation {
                id: anim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: box
                anchors.fill: parent
                anchors.margins: Theme.gapLarge
                spacing: Theme.gap

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    MaterialIcon { icon: "photo_library"; size: 20; color: Theme.text }
                    Text {
                        Layout.fillWidth: true
                        text: "Tote"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.Bold
                    }
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: openMa.containsMouse ? Theme.hover : "transparent"
                        MaterialIcon { anchors.centerIn: parent; icon: "folder_open"; size: 18; color: Theme.text }
                        MouseArea {
                            id: openMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Tote.reveal(); ShellState.closeAll(); }
                        }
                    }
                }

                Text {
                    text: "Recent screenshots"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }

                // Thumbnail grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: Theme.gap
                    rowSpacing: Theme.gap

                    Repeater {
                        model: Tote.recent
                        delegate: Rectangle {
                            id: tile
                            required property var modelData        // absolute path
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * 0.66
                            radius: Theme.radius
                            color: Theme.surfaceHigh
                            clip: true
                            border.width: 1
                            border.color: Theme.outline

                            Image {
                                anchors.fill: parent
                                source: "file://" + tile.modelData
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 240
                                asynchronous: true
                                cache: false
                            }

                            // Hover scrim + actions
                            Rectangle {
                                anchors.fill: parent
                                color: tileMa.containsMouse ? "#66000000" : "#00000000"
                                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.gap
                                opacity: tileMa.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

                                TileAction { icon: "content_copy"; onTriggered: Tote.copy(tile.modelData) }
                                TileAction { icon: "open_in_new"; onTriggered: { Tote.open(tile.modelData); ShellState.closeAll(); } }
                                TileAction { icon: "delete"; danger: true; onTriggered: Tote.remove(tile.modelData) }
                            }

                            MouseArea {
                                id: tileMa
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }
        }
    }

    component TileAction: Rectangle {
        property string icon: ""
        property bool danger: false
        signal triggered()
        width: 32; height: 32; radius: 16
        color: taMa.containsMouse ? (danger ? Theme.bad : Theme.accent) : "#88000000"
        MaterialIcon {
            anchors.centerIn: parent
            icon: parent.icon
            size: 18
            color: taMa.containsMouse ? (parent.danger ? "#ffffff" : Theme.textOnAccent) : "#ffffff"
        }
        MouseArea {
            id: taMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }
}
