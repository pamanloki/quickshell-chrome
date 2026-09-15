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
    property string expanded: ""   // "" | "wifi" | "bt" | "night" | "audio"
    property bool captureMenuOpen: false
    property real captureMenuX: 0
    property real captureMenuY: 0

    function toggleExpand(which) {
        expanded = (expanded === which) ? "" : which;
        if (expanded === "wifi") Network.scan();
        else if (expanded === "bt") Bluetooth.scan();
        else if (expanded === "night") Nightlight.refresh();
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

                // ── User header ─────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 2
                    spacing: 10
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                            color: Theme.textOnAccent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.Bold
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: Quickshell.env("USER") || "User"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Bold
                        }
                        Text {
                            text: "Signed in"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }

                // ── Now Playing (MPRIS) ─────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    visible: Player.has
                    implicitHeight: npCol.implicitHeight + 20
                    radius: Theme.radius
                    color: Theme.surfaceBright

                    ColumnLayout {
                        id: npCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                width: 56; height: 56; radius: Theme.radiusSmall
                                color: Theme.surfaceHigh
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: Player.artUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: Player.artUrl.length > 0
                                }
                                MaterialIcon {
                                    anchors.centerIn: parent
                                    icon: "music_note"; size: 26; color: Theme.textDim
                                    visible: Player.artUrl.length === 0
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: Player.title || "Unknown"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: Player.artist.length > 0
                                    text: Player.artist
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    elide: Text.ElideRight
                                }
                            }
                            QsIconButton { diameter: 34; icon: "skip_previous"; onClicked: Player.previous() }
                            QsIconButton { diameter: 42; icon: Player.playing ? "pause" : "play_arrow"; iconColor: Theme.accent; onClicked: Player.playPause() }
                            QsIconButton { diameter: 34; icon: "skip_next"; onClicked: Player.next() }
                        }

                        // scrubber
                        Rectangle {
                            Layout.fillWidth: true
                            visible: Player.length > 0
                            height: 6
                            radius: 3
                            color: Theme.surfaceHigh
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height
                                radius: 3
                                width: parent.width * Player.fraction
                                color: Theme.accent
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -6
                                anchors.bottomMargin: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (m) => Player.seek(m.x / width)
                            }
                        }
                    }
                }

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
                        icon: Notifications.doNotDisturb ? "do_not_disturb_on" : "notifications"
                        title: "Do not disturb"
                        subtitle: Notifications.doNotDisturb ? "On" : "Off"
                        active: Notifications.doNotDisturb
                        onToggled: Notifications.doNotDisturb = !Notifications.doNotDisturb
                    }
                    QsToggle {
                        Layout.fillWidth: true
                        icon: "nightlight"
                        title: "Night Light"
                        subtitle: Nightlight.active ? (Nightlight.temp + "K") : "Off"
                        active: Nightlight.active
                        hasDetail: true
                        onToggled: Nightlight.toggle()
                        onDetail: qs.toggleExpand("night")
                    }
                    QsToggle {
                        Layout.fillWidth: true
                        icon: "screenshot_region"
                        title: "Screen capture"
                        subtitle: Screenshot.modeLabel
                        onToggled: { ShellState.closeAll(); Screenshot.capture(); }
                        onRightClicked: (gx, gy) => { qs.captureMenuX = gx; qs.captureMenuY = gy; qs.captureMenuOpen = true; }
                    }
                    QsToggle {
                        Layout.fillWidth: true
                        icon: "dark_mode"
                        title: "Theme"
                        subtitle: Flavours.mode === "light" ? "Light" : "Dark"
                        onToggled: Flavours.toggleMode()
                        hasDetail: true
                        onDetail: ShellState.toggleSettings("theme")
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

                // ── Inline Night Light panel ────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    visible: qs.expanded === "night"
                    Layout.preferredHeight: visible ? nightCol.implicitHeight + 20 : 0
                    radius: Theme.radius
                    color: Theme.surface
                    clip: true

                    Column {
                        id: nightCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Item {
                            width: parent.width
                            height: 18
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Color temperature"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: Nightlight.temp + "K"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        QsSlider {
                            width: parent.width
                            icon: "nightlight"
                            value: Nightlight.fraction
                            onMoved: (v) => Nightlight.setTemp(
                                Nightlight.minTemp + v * (Nightlight.maxTemp - Nightlight.minTemp))
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
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap
                    QsSlider {
                        Layout.fillWidth: true
                        icon: Audio.icon
                        iconClickable: true
                        value: Audio.volume
                        onMoved: (v) => Audio.setVolume(v)
                        onIconClicked: Audio.toggleMute()
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 40; height: 40; radius: 20
                        color: qs.expanded === "audio" ? Theme.accent
                             : (audioBtn.containsMouse ? Theme.hover : Theme.surfaceHigh)
                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "speaker"
                            size: 20
                            color: qs.expanded === "audio" ? Theme.textOnAccent : Theme.text
                        }
                        MouseArea {
                            id: audioBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: qs.toggleExpand("audio")
                        }
                    }
                }

                // Inline audio-output picker
                Rectangle {
                    Layout.fillWidth: true
                    visible: qs.expanded === "audio"
                    Layout.preferredHeight: visible ? Math.min(180, sinkList.contentHeight + 8) : 0
                    radius: Theme.radius
                    color: Theme.surface
                    clip: true

                    ListView {
                        id: sinkList
                        anchors.fill: parent
                        anchors.margins: 4
                        model: Audio.sinks
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds

                        header: Item {
                            width: sinkList.width; height: 26
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Output device"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isDefault: Audio.sink === modelData
                            width: sinkList.width
                            height: 38
                            radius: Theme.radiusSmall
                            color: sinkMa.containsMouse ? Theme.hover : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8
                                MaterialIcon {
                                    icon: "speaker"
                                    size: 18
                                    color: parent.parent.isDefault ? Theme.accent : Theme.text
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: Audio.nodeLabel(modelData)
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    elide: Text.ElideRight
                                }
                                MaterialIcon {
                                    icon: "check"
                                    size: 18
                                    color: Theme.accent
                                    visible: parent.parent.isDefault
                                }
                            }
                            MouseArea {
                                id: sinkMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Audio.setDefaultSink(modelData)
                            }
                        }
                    }
                }

                // Per-app volume mixer
                Rectangle {
                    Layout.fillWidth: true
                    visible: qs.expanded === "audio" && Audio.streams.length > 0
                    Layout.preferredHeight: visible ? Math.min(200, mixList.contentHeight + 8) : 0
                    radius: Theme.radius
                    color: Theme.surface
                    clip: true

                    ListView {
                        id: mixList
                        anchors.fill: parent
                        anchors.margins: 4
                        model: Audio.streams
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds

                        header: Item {
                            width: mixList.width; height: 26
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "App volumes"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        delegate: Item {
                            required property var modelData
                            width: mixList.width
                            height: 62
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 4
                                Text {
                                    width: parent.width
                                    text: Audio.streamLabel(modelData)
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                QsSlider {
                                    width: parent.width
                                    icon: "volume_up"
                                    value: modelData.audio ? modelData.audio.volume : 0
                                    onMoved: (v) => Audio.setStreamVolume(modelData, v)
                                }
                            }
                        }
                    }
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
                            font.weight: Font.Bold
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
                        onClicked: ShellState.toggleSettings()
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

    // ── Screen-capture right-click menu (region/full × clipboard/file) ───────
    Item {
        anchors.fill: parent
        visible: qs.captureMenuOpen

        MouseArea { anchors.fill: parent; onPressed: qs.captureMenuOpen = false }

        Rectangle {
            id: capMenu
            width: 232
            height: capCol.implicitHeight + 10
            radius: Theme.radius
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline
            x: Math.max(Theme.gap, Math.min(qs.captureMenuX - width / 2, parent.width - width - Theme.gap))
            y: Math.max(Theme.gap, qs.captureMenuY - height - Theme.gap)

            MouseArea { anchors.fill: parent }

            Column {
                id: capCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 5 }
                spacing: 1

                Repeater {
                    model: Screenshot.modes
                    delegate: Rectangle {
                        required property var modelData
                        width: capCol.width
                        height: 38
                        radius: Theme.radiusSmall
                        readonly property bool sel: Screenshot.mode === modelData.id
                        color: capMa.containsMouse ? Theme.hover : (sel ? Theme.surfaceHigh : "transparent")

                        MaterialIcon {
                            id: capIcon
                            anchors.left: parent.left; anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            icon: modelData.icon; size: 18; color: Theme.text
                        }
                        Text {
                            anchors.left: capIcon.right; anchors.leftMargin: 10
                            anchors.right: capChk.left; anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }
                        MaterialIcon {
                            id: capChk
                            anchors.right: parent.right; anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "check"; size: 16; color: Theme.accent
                            visible: parent.sel
                        }
                        MouseArea {
                            id: capMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                qs.captureMenuOpen = false;
                                ShellState.closeAll();
                                Screenshot.pickAndCapture(modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }
}
