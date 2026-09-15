import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * ChromeOS quick-settings bubble, anchored bottom-right just above the status
 * area. Feature pods (with inline Wi-Fi / Bluetooth lists), brightness & volume
 * sliders, and a footer with the date and system buttons. Created on demand by
 * OverlayHost; a full-screen scrim closes it on click / Esc.
 */
PanelWindow {
    id: qs

    WlrLayershell.namespace: "quickshell:quicksettings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    // Local UI state
    property bool dnd: false
    property bool nightLight: false
    property string expanded: ""   // "" | "wifi" | "bt"

    function toggleExpand(which) {
        expanded = (expanded === which) ? "" : which;
        if (expanded === "wifi") Network.scan();
        else if (expanded === "bt") Bluetooth.scan();
    }

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
            width: 380
            implicitHeight: layout.implicitHeight + 2 * Theme.gapLarge
            height: implicitHeight
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline

            Component.onCompleted: {
                Network.refresh();
                Bluetooth.refresh();
                Brightness.refresh();
                scale = 0.94; opacity = 0;
                showAnim.start();
            }
            transformOrigin: Item.BottomRight
            ParallelAnimation {
                id: showAnim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }

            MouseArea { anchors.fill: parent }   // swallow scrim clicks

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: Theme.gapLarge
                spacing: Theme.gap

                // ── Feature pods ────────────────────────────────────────────
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Theme.gap
                    columnSpacing: Theme.gap

                    QsToggle {
                        Layout.fillWidth: true
                        icon: Network.icon
                        title: "Network"
                        subtitle: Network.connected ? (Network.name || "Connected")
                                                    : (Network.wifiEnabled ? "Not connected" : "Wi-Fi off")
                        active: Network.connected
                        hasDetail: true
                        onToggled: Network.toggleWifi()
                        onDetail: qs.toggleExpand("wifi")
                    }
                    QsToggle {
                        Layout.fillWidth: true
                        icon: Bluetooth.icon
                        title: "Bluetooth"
                        subtitle: Bluetooth.connected ? Bluetooth.connectedName
                                                      : (Bluetooth.powered ? "On" : "Off")
                        active: Bluetooth.powered
                        hasDetail: true
                        onToggled: Bluetooth.toggle()
                        onDetail: qs.toggleExpand("bt")
                    }
                    QsToggle {
                        Layout.fillWidth: true
                        icon: qs.dnd ? "do_not_disturb_on" : "notifications"
                        title: "Do not disturb"
                        subtitle: qs.dnd ? "On" : "Off"
                        active: qs.dnd
                        onToggled: qs.dnd = !qs.dnd
                    }
                    QsToggle {
                        Layout.fillWidth: true
                        icon: "nightlight"
                        title: "Night Light"
                        subtitle: qs.nightLight ? "On" : "Off"
                        active: qs.nightLight
                        onToggled: {
                            qs.nightLight = !qs.nightLight;
                            Quickshell.execDetached(qs.nightLight
                                ? ["sh", "-c", "pkill wlsunset; wlsunset -t 4000 -T 6500 &"]
                                : ["pkill", "wlsunset"]);
                        }
                    }
                }

                // ── Inline Wi-Fi list ───────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    visible: qs.expanded === "wifi"
                    Layout.preferredHeight: visible ? Math.min(210, wifiList.contentHeight + 8) : 0
                    radius: Theme.radius
                    color: Theme.surface
                    clip: true

                    ListView {
                        id: wifiList
                        anchors.fill: parent
                        anchors.margins: 4
                        model: Network.networks
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds

                        header: Item {
                            width: wifiList.width
                            height: 26
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: Network.scanning ? "Scanning…"
                                                       : (wifiList.count === 0 ? "No networks" : "Wi-Fi networks")
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            width: wifiList.width
                            height: 40
                            radius: Theme.radiusSmall
                            color: wifiMa.containsMouse ? Theme.hover : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8
                                MaterialIcon {
                                    icon: modelData.signal >= 60 ? "network_wifi"
                                        : modelData.signal >= 30 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                                    size: 18
                                    color: Theme.text
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.ssid
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    elide: Text.ElideRight
                                }
                                MaterialIcon {
                                    icon: "lock"
                                    size: 14
                                    color: Theme.textFaint
                                    visible: (modelData.security || "").length > 0 && modelData.security !== "--"
                                }
                                MaterialIcon {
                                    icon: "check"
                                    size: 18
                                    color: Theme.accent
                                    visible: modelData.active
                                }
                            }
                            MouseArea {
                                id: wifiMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Network.connect(modelData.ssid)
                            }
                        }
                    }
                }

                // ── Inline Bluetooth list ───────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    visible: qs.expanded === "bt"
                    Layout.preferredHeight: visible ? Math.min(210, btList.contentHeight + 8) : 0
                    radius: Theme.radius
                    color: Theme.surface
                    clip: true

                    ListView {
                        id: btList
                        anchors.fill: parent
                        anchors.margins: 4
                        model: Bluetooth.devices
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds

                        header: Item {
                            width: btList.width
                            height: 26
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: !Bluetooth.powered ? "Bluetooth is off"
                                    : Bluetooth.scanning ? "Scanning…"
                                    : (btList.count === 0 ? "No devices" : "Devices")
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            width: btList.width
                            height: 40
                            radius: Theme.radiusSmall
                            color: btMa.containsMouse ? Theme.hover : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8
                                MaterialIcon {
                                    icon: modelData.connected ? "bluetooth_connected" : "bluetooth"
                                    size: 18
                                    color: modelData.connected ? Theme.accent : Theme.text
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.connected ? "Connected" : ""
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                            MouseArea {
                                id: btMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.connected ? Bluetooth.disconnect(modelData.mac)
                                                               : Bluetooth.connect(modelData.mac)
                            }
                        }
                    }
                }

                // ── Sliders ─────────────────────────────────────────────────
                QsSlider {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    visible: Brightness.available
                    icon: "brightness_high"
                    value: Brightness.fraction
                    onMoved: (v) => Brightness.set(v)
                }
                QsSlider {
                    Layout.fillWidth: true
                    icon: Audio.icon
                    iconClickable: true
                    value: Audio.volume
                    onMoved: (v) => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Theme.outline
                }

                // ── Footer ──────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap

                    Column {
                        Layout.fillWidth: true
                        Text {
                            text: Time.dateLong
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Medium
                        }
                        Text {
                            text: Battery.available
                                  ? (Battery.percent + "% • " + (Battery.charging ? "Charging" : (Battery.timeRemaining ? Battery.timeRemaining + " left" : "On battery")))
                                  : "Quick settings"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    QsIconButton {
                        icon: "settings"
                        onClicked: {
                            ShellState.closeAll();
                            Quickshell.execDetached(["sh", "-c",
                                "XDG_CURRENT_DESKTOP= gnome-control-center || systemsettings || xfce4-settings-manager || true"]);
                        }
                    }
                    QsIconButton {
                        icon: "lock"
                        onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl lock-session"]); }
                    }
                    QsIconButton {
                        icon: "power_settings_new"
                        iconColor: Theme.bad
                        onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "wlogout || systemctl poweroff"]); }
                    }
                }
            }
        }
    }
}
