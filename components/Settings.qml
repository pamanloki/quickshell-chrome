import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * ChromeOS-style Settings window: a centered panel with a left category rail
 * and a right content pane (Personalization / Device / About) — not one long
 * scroll. Opened from the quick-settings gear; scrim / Esc closes.
 */
PanelWindow {
    id: win

    WlrLayershell.namespace: "quickshell:settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    property string section: "personalization"

    // dim backdrop like a real settings window
    Rectangle { anchors.fill: parent; color: Theme.overlayScrim }
    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Loader {
        active: true
        anchors.centerIn: parent
        onLoaded: { Flavours.refresh(); Wallpaper.refresh(); Updates.refresh(); SysInfo.refresh(); }

        sourceComponent: Rectangle {
            id: bubble
            width: Math.min(780, win.width - 80)
            height: Math.min(540, win.height - 120)
            radius: Theme.radiusLarge
            color: Theme.surface
            border.width: 1
            border.color: Theme.outline
            clip: true

            Component.onCompleted: { scale = 0.96; opacity = 0; anim.start(); }
            ParallelAnimation {
                id: anim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutCubic }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }
            MouseArea { anchors.fill: parent }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── Sidebar ─────────────────────────────────────────────────
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 220
                    color: Theme.surfaceBright

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.gap
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            Layout.margins: 10
                            Layout.bottomMargin: 6
                            text: "Settings"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLarge
                            font.weight: Font.Bold
                        }

                        NavItem { icon: "brush"; label: "Personalization"; sect: "personalization" }
                        NavItem { icon: "tune"; label: "Device"; sect: "device" }
                        NavItem { icon: "info"; label: "About"; sect: "about" }

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.outline }

                // ── Content pane ────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Close button (top-right of the pane)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 14
                        z: 2
                        width: 30; height: 30; radius: 15
                        color: closeMa.containsMouse ? Theme.hover : Theme.surfaceHigh
                        MaterialIcon { anchors.centerIn: parent; icon: "close"; size: 18; color: Theme.text }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.closeAll() }
                    }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 24
                        anchors.topMargin: 20
                        clip: true
                        contentHeight: pane.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: pane
                            width: parent.width
                            spacing: 18

                            Text {
                                text: win.section === "personalization" ? "Personalization"
                                    : win.section === "device" ? "Device"
                                    : "About"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTitle
                                font.weight: Font.Bold
                            }

                            // ── Personalization ─────────────────────────────
                            SectionLabel { text: "Wallpaper"; visible: win.section === "personalization" }
                            GridView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible ? Math.min(300, Math.ceil(Wallpaper.walls.length / colsN) * 84 + 8) : 0
                                visible: win.section === "personalization" && Wallpaper.walls.length > 0
                                readonly property int colsN: Math.max(1, Math.floor(width / 148))
                                cellWidth: width / colsN
                                cellHeight: 84
                                clip: true
                                interactive: false
                                model: Wallpaper.walls
                                delegate: Item {
                                    required property var modelData
                                    width: GridView.view.cellWidth
                                    height: 84
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width - 8
                                        height: 76
                                        radius: Theme.radiusSmall
                                        color: Theme.surfaceHigh
                                        clip: true
                                        border.width: Wallpaper.current === modelData ? 3 : 0
                                        border.color: Theme.accent
                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: Wallpaper.current === modelData ? 3 : 0
                                            source: "file://" + modelData
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            sourceSize.width: 300
                                            sourceSize.height: 180
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpaper.apply(modelData) }
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: win.section === "personalization" && Wallpaper.walls.length === 0
                                text: "No images in " + Wallpaper.dir
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                wrapMode: Text.Wrap
                            }

                            SectionLabel { text: "Theme (Base16)"; visible: win.section === "personalization" }
                            Flow {
                                Layout.fillWidth: true
                                visible: win.section === "personalization"
                                spacing: 6
                                Repeater {
                                    model: Flavours.schemes
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool sel: Flavours.current === modelData.slug
                                        height: 32
                                        width: pillTxt.implicitWidth + 24
                                        radius: 16
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
                                    height: 32; width: fEmpty.implicitWidth + 24; radius: 16; color: Theme.surfaceHigh
                                    Text { id: fEmpty; anchors.centerIn: parent; text: "Install `flavours`"; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                                }
                            }

                            // ── Device ──────────────────────────────────────
                            SectionLabel { text: "Updates"; visible: win.section === "device" }
                            Rectangle {
                                Layout.fillWidth: true
                                visible: win.section === "device"
                                height: 56
                                radius: Theme.radius
                                color: Theme.surfaceBright
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 12
                                    MaterialIcon { icon: "system_update_alt"; size: 22; color: Updates.count > 0 ? Theme.accent : Theme.textDim }
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
                                        Text { text: "xbps (Void Linux)"; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                                    }
                                    PillButton {
                                        label: Updates.count > 0 ? "Update" : "Check"
                                        accent: Updates.count > 0
                                        onClicked: Updates.count > 0 ? Updates.update() : Updates.refresh()
                                    }
                                }
                            }

                            SectionLabel { text: "Power"; visible: win.section === "device" }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: win.section === "device"
                                spacing: 8
                                PowerBtn { icon: "lock"; label: "Lock"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl lock-session"]); } }
                                PowerBtn { icon: "bedtime"; label: "Sleep"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]); } }
                                PowerBtn { icon: "restart_alt"; label: "Restart"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl reboot || systemctl reboot"]); } }
                                PowerBtn { icon: "power_settings_new"; label: "Off"; danger: true; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl poweroff || systemctl poweroff"]); } }
                            }

                            // ── About ───────────────────────────────────────
                            Rectangle {
                                Layout.fillWidth: true
                                visible: win.section === "about"
                                implicitHeight: aboutCol.implicitHeight + 24
                                radius: Theme.radius
                                color: Theme.surfaceBright
                                ColumnLayout {
                                    id: aboutCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 8
                                    AboutRow { k: "Device"; v: SysInfo.user + "@" + SysInfo.host }
                                    AboutRow { k: "Operating system"; v: SysInfo.distro }
                                    AboutRow { k: "Kernel"; v: SysInfo.kernel }
                                    AboutRow { k: "Compositor"; v: SysInfo.wm }
                                    AboutRow { k: "Uptime"; v: SysInfo.uptime }
                                    AboutRow { k: "Shell"; v: "quickshell-chrome" }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: win.section === "about"
                                text: "A Chrome OS–style desktop shell for Quickshell."
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                wrapMode: Text.Wrap
                            }

                            Item { Layout.fillHeight: true; Layout.preferredHeight: 4 }
                        }
                    }
                }
            }
        }
    }

    // ── inline components ───────────────────────────────────────────────────
    component NavItem: Rectangle {
        id: nav
        property string icon: ""
        property string label: ""
        property string sect: ""
        readonly property bool sel: win.section === sect
        Layout.fillWidth: true
        implicitHeight: 42
        radius: Theme.radiusPill
        color: sel ? Theme.accent : (navMa.containsMouse ? Theme.hover : "transparent")
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 12
            MaterialIcon { icon: nav.icon; size: 20; fill: nav.sel ? 1 : 0; color: nav.sel ? Theme.textOnAccent : Theme.text }
            Text {
                Layout.fillWidth: true
                text: nav.label
                color: nav.sel ? Theme.textOnAccent : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
        MouseArea { id: navMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.section = nav.sect }
    }

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
        Text { text: k; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontBody }
        Item { Layout.fillWidth: true }
        Text { text: v; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontBody; font.weight: Font.Medium; elide: Text.ElideRight; Layout.maximumWidth: 320; horizontalAlignment: Text.AlignRight }
    }

    component PillButton: Rectangle {
        id: pill
        property string label: ""
        property bool accent: false
        signal clicked()
        implicitWidth: pbTxt.implicitWidth + 26
        implicitHeight: 34
        radius: 17
        color: accent ? Theme.accent : (pbMa.containsMouse ? Theme.hover : Theme.surfaceHigh)
        Text { id: pbTxt; anchors.centerIn: parent; text: pill.label; color: pill.accent ? Theme.textOnAccent : Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.Medium }
        MouseArea { id: pbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }

    component PowerBtn: Rectangle {
        id: pb
        property string icon: ""
        property string label: ""
        property bool danger: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 62
        radius: Theme.radius
        color: powMa.containsMouse ? Theme.hover : Theme.surfaceBright
        Column {
            anchors.centerIn: parent
            spacing: 4
            MaterialIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: pb.icon; size: 22; color: pb.danger ? Theme.bad : Theme.text }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: pb.label; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
        }
        MouseArea { id: powMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
    }
}
