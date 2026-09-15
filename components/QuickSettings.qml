import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * ChromeOS quick-settings bubble, anchored to the bottom-right above the status
 * area. Feature pods + brightness/volume sliders + a footer with the date and
 * system icon buttons. Backed by a full-screen scrim that closes on click/Esc.
 */
PanelWindow {
    id: qs
    required property var modelData
    screen: modelData

    visible: State.quickSettingsOpen && (State.activeScreen === null || State.activeScreen === modelData)

    WlrLayershell.namespace: "quickshell:quicksettings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    // Local UI state
    property bool dnd: false
    property bool nightLight: false

    // Scrim / click-away
    MouseArea {
        anchors.fill: parent
        onClicked: State.closeAll()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: State.closeAll()
    }

    // ── The bubble ──────────────────────────────────────────────────────────
    Loader {
        active: qs.visible
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.shelfHeight + Theme.gap

        sourceComponent: Rectangle {
            id: bubble
            width: 372
            implicitHeight: layout.implicitHeight + 2 * Theme.gapLarge
            height: implicitHeight
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline

            // Entrance animation
            transformOrigin: Item.BottomRight
            Component.onCompleted: {
                scale = 0.92; opacity = 0;
                showAnim.start();
            }
            ParallelAnimation {
                id: showAnim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }

            // Block scrim clicks landing on the bubble
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: Theme.gapLarge
                spacing: Theme.gap

                // Feature pods grid
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
                                                    : (Network.wifiEnabled ? "Not connected" : "Off")
                        active: Network.connected || Network.wifiEnabled
                        hasDetail: true
                        onToggled: Network.toggleWifi()
                        onDetail: Network.openSettings()
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
                        onDetail: Bluetooth.openSettings()
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

                // Brightness
                QsSlider {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    visible: Brightness.available
                    icon: "brightness_high"
                    value: Brightness.fraction
                    onMoved: (v) => Brightness.set(v)
                }

                // Volume
                QsSlider {
                    Layout.fillWidth: true
                    icon: Audio.icon
                    iconClickable: true
                    value: Audio.volume
                    onMoved: (v) => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Theme.outline
                }

                // Footer: date + system buttons
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
                        onClicked: { State.closeAll(); Quickshell.execDetached(["sh", "-c", "gnome-control-center || xdg-open settings || systemsettings"]); }
                    }
                    QsIconButton {
                        icon: "lock"
                        onClicked: { State.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl lock-session"]); }
                    }
                    QsIconButton {
                        icon: "power_settings_new"
                        iconColor: Theme.bad
                        onClicked: { State.closeAll(); Quickshell.execDetached(["sh", "-c", "systemctl poweroff"]); }
                    }
                }
            }
        }
    }
}
