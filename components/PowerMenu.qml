import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * ChromeOS-style power menu, opened from the Quick Settings power button.
 * Lists Lock / Sleep / Sign out / Restart / Power off; destructive actions ask
 * for confirmation first. Bottom-right above the shelf; scrim / Esc closes.
 */
PanelWindow {
    id: power

    WlrLayershell.namespace: "quickshell:powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    // Pending destructive action awaiting confirmation, or null.
    property var pending: null

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    function trigger(a) {
        if (a.confirm) {
            power.pending = a;
        } else {
            Power.run(a.id);
            ShellState.closeAll();
        }
    }

    Loader {
        active: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.gap

        sourceComponent: Rectangle {
            id: bubble
            width: 260
            implicitHeight: content.implicitHeight + 2 * Theme.gapLarge
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

            // ── Action list ─────────────────────────────────────────────────
            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.gapLarge
                spacing: 2
                visible: power.pending === null

                Repeater {
                    model: Power.actions
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 44
                        radius: Theme.radiusSmall
                        color: itemMa.containsMouse
                            ? (modelData.id === "poweroff" ? Theme._a(Theme.bad, 0.15) : Theme.hover)
                            : "transparent"

                        MaterialIcon {
                            id: itemIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            icon: modelData.icon
                            size: 20
                            color: modelData.id === "poweroff" ? Theme.bad : Theme.text
                        }
                        Text {
                            anchors.left: itemIcon.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: modelData.id === "poweroff" ? Theme.bad : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Medium
                        }
                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: power.trigger(modelData)
                        }
                    }
                }
            }

            // ── Confirmation ────────────────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.gapLarge
                spacing: Theme.gap
                visible: power.pending !== null

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: power.pending ? power.pending.icon : "help"
                    size: 34
                    color: Theme.text
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: power.pending ? (power.pending.label + " now?") : ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: Theme.gap

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.radiusSmall
                        color: cancelMa.containsMouse ? Theme.surfaceHigh : Theme.surface
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Medium
                        }
                        MouseArea {
                            id: cancelMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: power.pending = null
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.radiusSmall
                        color: confirmMa.containsMouse ? Theme._a(Theme.bad, 0.85) : Theme.bad
                        Text {
                            anchors.centerIn: parent
                            text: power.pending ? power.pending.label : ""
                            color: "#ffffff"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            id: confirmMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const a = power.pending;
                                power.pending = null;
                                if (a) Power.run(a.id);
                                ShellState.closeAll();
                            }
                        }
                    }
                }
            }
        }
    }
}
