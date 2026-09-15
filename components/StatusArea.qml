import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

/**
 * ChromeOS status area at the far right of the shelf. Two click zones on one
 * pill: the icons (network / bluetooth / battery, plus an unread-notification
 * dot) open Quick Settings; the clock opens the Calendar.
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
        color: (ShellState.quickSettingsOpen || ShellState.calendarOpen || ShellState.notificationsOpen) ? Theme.surfaceHigh : "transparent"
        implicitWidth: content.implicitWidth + 24

        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.gap

            // ── Notification bell → Notification Center ─────────────────────
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 24
                implicitHeight: Theme.iconSize

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: Notifications.doNotDisturb ? "notifications_off"
                        : (Notifications.history.length > 0 ? "notifications" : "notifications_none")
                    size: 18
                    color: Theme.text
                }

                // unread count badge
                Rectangle {
                    visible: Notifications.unread > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.rightMargin: -2
                    width: Math.max(14, badge.implicitWidth + 6)
                    height: 14
                    radius: 7
                    color: Theme.bad
                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: Notifications.unread > 9 ? "9+" : Notifications.unread
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ShellState.activeScreen = root.targetScreen;
                        ShellState.toggleNotifications();
                    }
                }
            }

            // ── Icons zone → Quick Settings ─────────────────────────────────
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: icons.implicitWidth
                implicitHeight: Theme.iconSize

                RowLayout {
                    id: icons
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
                        MaterialIcon { icon: Battery.icon; size: 18; fill: 1; color: Battery.color }
                        Text {
                            text: Battery.percent + "%"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.Medium
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ShellState.activeScreen = root.targetScreen;
                        ShellState.toggleQuickSettings();
                    }
                }
            }

            Rectangle {
                width: 1
                height: 16
                color: Theme.outlineStrong
                Layout.alignment: Qt.AlignVCenter
            }

            // ── Clock zone → Calendar ───────────────────────────────────────
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clock.implicitWidth
                implicitHeight: Theme.iconSize

                Text {
                    id: clock
                    anchors.centerIn: parent
                    text: Time.time
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ShellState.activeScreen = root.targetScreen;
                        ShellState.toggleCalendar();
                    }
                }
            }
        }
    }
}
