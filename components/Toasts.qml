import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "root:/config"
import "root:/services"

/**
 * Transient notification toasts, stacked at the bottom-right above the shelf.
 * ChromeOS-style rounded cards with icon, title, body and a close button; they
 * auto-dismiss unless the notification is critical. One window per screen,
 * sized to its content so the rest of the screen stays clickable.
 */
PanelWindow {
    id: toasts
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { bottom: true; right: true }
    margins.bottom: Theme.shelfHeight + Theme.gap
    margins.right: Theme.gapLarge
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 372
    implicitHeight: Math.max(1, col.implicitHeight)
    visible: rep.count > 0

    Column {
        id: col
        anchors.fill: parent
        spacing: Theme.gap

        Repeater {
            id: rep
            model: Notifications.list

            delegate: Rectangle {
                id: toast
                required property var modelData        // Notification
                width: col.width
                implicitHeight: mainCol.implicitHeight + 20
                radius: Theme.radius
                color: Theme.surfaceGlass
                border.width: 1
                border.color: Theme.outline

                readonly property bool critical:
                    modelData.urgency === NotificationUrgency.Critical

                // entrance
                opacity: 0
                x: 20
                Component.onCompleted: { opacity = 1; x = 0; }
                Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
                Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }

                Timer {
                    running: !toast.critical
                    interval: 5000
                    onTriggered: toast.modelData.dismiss()
                }

                ColumnLayout {
                    id: mainCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 8

                    RowLayout {
                    id: row
                    Layout.fillWidth: true
                    spacing: 12

                    IconImage {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 34
                        implicitHeight: 34
                        source: {
                            const img = toast.modelData.image || "";
                            if (img.length > 0) return img;
                            const ic = toast.modelData.appIcon || "";
                            return Quickshell.iconPath(ic || "dialog-information", "dialog-information");
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: toast.modelData.summary || toast.modelData.appName || "Notification"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: (toast.modelData.body || "").length > 0
                            text: toast.modelData.body
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        width: 28
                        height: 28
                        radius: 14
                        color: closeMa.containsMouse ? Theme.hover : "transparent"
                        MaterialIcon { anchors.centerIn: parent; icon: "close"; size: 18; color: Theme.textDim }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toast.modelData.dismiss()
                        }
                    }
                    }

                    // Action buttons
                    Flow {
                        Layout.fillWidth: true
                        Layout.leftMargin: 46
                        spacing: 6
                        visible: (toast.modelData.actions ? toast.modelData.actions.length : 0) > 0
                        Repeater {
                            model: toast.modelData.actions
                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: aTxt.implicitWidth + 22
                                height: 30
                                radius: 15
                                color: aMa.containsMouse ? Theme.surfaceHigh : Theme.surface
                                Text {
                                    id: aTxt
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Font.Medium
                                }
                                MouseArea {
                                    id: aMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { modelData.invoke(); toast.modelData.dismiss(); }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
