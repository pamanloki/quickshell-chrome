import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * Clipboard history popup (ChromeOS Search+V), backed by cliphist. Lists recent
 * clips; click one to copy it back for pasting, or remove individual entries.
 * Bottom-left above the shelf; scrim / Esc closes.
 */
PanelWindow {
    id: clip

    WlrLayershell.namespace: "quickshell:clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    Component.onCompleted: Clipboard.refresh()

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Loader {
        active: true
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.gap

        sourceComponent: Rectangle {
            id: bubble
            width: 380
            implicitHeight: box.implicitHeight + 2 * Theme.gapLarge
            height: Math.min(implicitHeight, 520)
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline

            transformOrigin: Item.BottomLeft
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
                    MaterialIcon { icon: "content_paste"; size: 20; color: Theme.text }
                    Text {
                        Layout.fillWidth: true
                        text: "Clipboard"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.Bold
                    }
                    Rectangle {
                        visible: Clipboard.entries.length > 0
                        Layout.preferredWidth: clearRow.implicitWidth + 16
                        Layout.preferredHeight: 28
                        radius: 14
                        color: clearMa.containsMouse ? Theme.hover : "transparent"
                        Row {
                            id: clearRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialIcon { anchors.verticalCenter: parent.verticalCenter; icon: "delete_sweep"; size: 16; color: Theme.textDim }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Clear all"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.Medium
                            }
                        }
                        MouseArea {
                            id: clearMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Clipboard.clear()
                        }
                    }
                }

                // Empty state
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    Layout.bottomMargin: 12
                    horizontalAlignment: Text.AlignHCenter
                    visible: Clipboard.entries.length === 0
                    text: Clipboard.ready
                        ? "Clipboard history is empty.\nIs the cliphist watcher running?"
                        : "Loading…"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }

                // Clip list
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(contentHeight, 400)
                    visible: Clipboard.entries.length > 0
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: Clipboard.entries

                    delegate: Rectangle {
                        required property var modelData      // { id, preview }
                        width: list.width
                        height: 44
                        radius: Theme.radiusSmall
                        color: rowMa.containsMouse ? Theme.hover : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: delBtn.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            text: modelData.preview
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: delBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28; height: 28; radius: 14
                            color: delMa.containsMouse ? Theme.surfaceHigh : "transparent"
                            MaterialIcon { anchors.centerIn: parent; icon: "close"; size: 15; color: Theme.textDim }
                            MouseArea {
                                id: delMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Clipboard.remove(modelData.id)
                            }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            anchors.rightMargin: 34
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Clipboard.use(modelData.id); ShellState.closeAll(); }
                        }
                    }
                }
            }
        }
    }
}
