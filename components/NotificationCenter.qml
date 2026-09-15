import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/config"
import "root:/services"

/**
 * Dedicated notification center — its own panel (not merged into quick
 * settings), bottom-right above the shelf. Header with Clear all, a scrollable
 * history, and an empty state. Opened by the status-area bell.
 */
PanelWindow {
    id: nc

    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    function ago(ms) {
        const s = Math.max(0, Math.floor((Date.now() - ms) / 1000));
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Loader {
        active: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.gap

        onLoaded: Notifications.markRead()

        sourceComponent: Rectangle {
            id: bubble
            width: 390
            height: Math.min(nc.height - Theme.shelfHeight - 2 * Theme.gapLarge,
                             header.implicitHeight + list.contentHeight + 3 * Theme.gapLarge + 12)
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

            // Header
            RowLayout {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.gapLarge
                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Medium
                }
                Rectangle {
                    visible: Notifications.history.length > 0
                    width: clearTxt.implicitWidth + 20
                    height: 28
                    radius: 14
                    color: clearMa.containsMouse ? Theme.hover : Theme.surfaceHigh
                    Text {
                        id: clearTxt
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.clearHistory()
                    }
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: Notifications.history.length === 0
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "notifications_none"
                    size: 40
                    color: Theme.textFaint
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No notifications"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            // History
            ListView {
                id: list
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: Theme.gapLarge
                anchors.rightMargin: Theme.gapLarge
                anchors.topMargin: Theme.gap
                anchors.bottomMargin: Theme.gapLarge
                clip: true
                spacing: Theme.gap
                model: Notifications.history
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    width: list.width
                    implicitHeight: Math.max(58, drow.implicitHeight + 20)
                    radius: Theme.radius
                    color: Theme.surfaceHigh

                    RowLayout {
                        id: drow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 12

                        IconImage {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 30
                            implicitHeight: 30
                            source: {
                                const img = modelData.image || "";
                                if (img.length > 0) return img;
                                return Quickshell.iconPath(modelData.appIcon || "dialog-information", "dialog-information");
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary || modelData.appName
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: nc.ago(modelData.time)
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: (modelData.body || "").length > 0
                                text: modelData.body
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            width: 26; height: 26; radius: 13
                            color: dclose.containsMouse ? Theme.hover : "transparent"
                            MaterialIcon { anchors.centerIn: parent; icon: "close"; size: 16; color: Theme.textDim }
                            MouseArea {
                                id: dclose
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.removeHistory(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
