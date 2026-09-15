import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * In-shell Settings panel (opened by the quick-settings gear): Appearance
 * (Base16 theme via Flavours + wallpaper picker) and System (updates, about,
 * power). Bottom-right above the shelf; scrim / Esc closes.
 */
PanelWindow {
    id: win

    WlrLayershell.namespace: "quickshell:settings"
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
        onLoaded: { Flavours.refresh(); Wallpaper.refresh(); Updates.refresh(); SysInfo.refresh(); }

        sourceComponent: Rectangle {
            id: bubble
            width: 430
            height: Math.min(win.height - Theme.shelfHeight - 2 * Theme.gapLarge, 640)
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
                id: head
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.gapLarge
                Text {
                    Layout.fillWidth: true
                    text: "Settings"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: closeMa.containsMouse ? Theme.hover : Theme.surfaceHigh
                    MaterialIcon { anchors.centerIn: parent; icon: "close"; size: 18; color: Theme.text }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.closeAll() }
                }
            }

            Flickable {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: head.bottom
                anchors.bottom: parent.bottom
                anchors.margins: Theme.gapLarge
                anchors.topMargin: Theme.gap
                clip: true
                contentHeight: content.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: content
                    width: parent.width
                    spacing: 18

                    // ── Appearance: Theme ───────────────────────────────────
                    SectionLabel { text: "Theme" }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: Flavours.schemes
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: Flavours.current === modelData.slug
                                height: 30
                                width: pillTxt.implicitWidth + 22
                                radius: 15
                                color: sel ? Theme.accent : (pillMa.containsMouse ? Theme.hover : Theme.surfaceHigh)
                                Text {
                                    id: pillTxt
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: parent.sel ? Theme.textOnAccent : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Font.Medium
                                }
                                MouseArea { id: pillMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Flavours.apply(modelData.slug) }
                            }
                        }
                        Rectangle {
                            visible: Flavours.schemes.length === 0
                            height: 30; width: emptyTxt.implicitWidth + 22; radius: 15; color: Theme.surfaceHigh
                            Text { id: emptyTxt; anchors.centerIn: parent; text: "Install `flavours`"; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                        }
                    }

                    // ── Appearance: Wallpaper ───────────────────────────────
                    SectionLabel { text: "Wallpaper" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76
                        visible: Wallpaper.walls.length > 0
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true
                        model: Wallpaper.walls
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool sel: Wallpaper.current === modelData
                            width: 120; height: 72
                            radius: Theme.radiusSmall
                            color: Theme.surfaceHigh
                            clip: true
                            border.width: sel ? 2 : 0
                            border.color: Theme.accent
                            Image {
                                anchors.fill: parent
                                anchors.margins: parent.sel ? 2 : 0
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 240
                                sourceSize.height: 144
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpaper.apply(modelData) }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: Wallpaper.walls.length === 0
                        text: "No images in " + Wallpaper.dir
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.Wrap
                    }

                    // ── System: Updates ─────────────────────────────────────
                    SectionLabel { text: "System" }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: Theme.radius
                        color: Theme.surfaceHigh
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 10
                            MaterialIcon { icon: "system_update_alt"; size: 20; color: Updates.count > 0 ? Theme.accent : Theme.textDim }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: Updates.checking ? "Checking…"
                                        : Updates.count > 0 ? (Updates.count + " update" + (Updates.count > 1 ? "s" : "") + " available")
                                        : "System is up to date"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.Medium
                                }
                                Text {
                                    text: "xbps"
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                            PillButton {
                                label: Updates.count > 0 ? "Update" : "Check"
                                accent: Updates.count > 0
                                onClicked: Updates.count > 0 ? Updates.update() : Updates.refresh()
                            }
                        }
                    }

                    // ── System: About ───────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: aboutCol.implicitHeight + 20
                        radius: Theme.radius
                        color: Theme.surfaceHigh
                        ColumnLayout {
                            id: aboutCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 4
                            AboutRow { k: "Device"; v: SysInfo.user + "@" + SysInfo.host }
                            AboutRow { k: "OS"; v: SysInfo.distro }
                            AboutRow { k: "Kernel"; v: SysInfo.kernel }
                            AboutRow { k: "Compositor"; v: SysInfo.wm }
                            AboutRow { k: "Uptime"; v: SysInfo.uptime }
                            AboutRow { k: "Shell"; v: "quickshell-chrome" }
                        }
                    }

                    // ── System: Power ───────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        PowerBtn { icon: "lock"; label: "Lock"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl lock-session"]); } }
                        PowerBtn { icon: "bedtime"; label: "Sleep"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]); } }
                        PowerBtn { icon: "restart_alt"; label: "Restart"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "systemctl reboot || loginctl reboot"]); } }
                        PowerBtn { icon: "power_settings_new"; label: "Off"; danger: true; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"]); } }
                    }
                }
            }
        }
    }

    // ── inline components ───────────────────────────────────────────────────
    component SectionLabel: Text {
        Layout.fillWidth: true
        color: Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.weight: Font.Bold
    }

    component AboutRow: RowLayout {
        property string k: ""
        property string v: ""
        Layout.fillWidth: true
        Text { text: k; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
        Item { Layout.fillWidth: true }
        Text { text: v; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.Medium; elide: Text.ElideRight; Layout.maximumWidth: 240; horizontalAlignment: Text.AlignRight }
    }

    component PillButton: Rectangle {
        property string label: ""
        property bool accent: false
        signal clicked()
        implicitWidth: pbTxt.implicitWidth + 24
        implicitHeight: 32
        radius: 16
        color: accent ? Theme.accent : (pbMa.containsMouse ? Theme.hover : Theme.surface)
        Text { id: pbTxt; anchors.centerIn: parent; text: parent.label; color: parent.accent ? Theme.textOnAccent : Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.Medium }
        MouseArea { id: pbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    component PowerBtn: Rectangle {
        id: pb
        property string icon: ""
        property string label: ""
        property bool danger: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 58
        radius: Theme.radius
        color: powMa.containsMouse ? Theme.hover : Theme.surfaceHigh
        Column {
            anchors.centerIn: parent
            spacing: 3
            MaterialIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: pb.icon; size: 20; color: pb.danger ? Theme.bad : Theme.text }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: pb.label; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
        }
        MouseArea { id: powMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
    }
}
