import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * ChromeOS-style Settings window: centered, with a left category rail
 * (Wallpaper / Theme / Device / About) and a right content pane. Wallpaper and
 * Theme mirror quickshellku's logic — a 3-column wallpaper grid, and a
 * searchable family list with a light/dark switch.
 */
PanelWindow {
    id: win

    WlrLayershell.namespace: "quickshell:settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    property string section: "wallpaper"
    property string themeQuery: ""
    readonly property var filteredFamilies: {
        const q = themeQuery.toLowerCase().trim();
        if (!q) return Flavours.families;
        return Flavours.families.filter(s => s.toLowerCase().indexOf(q) !== -1);
    }
    function fileUrl(p) { return "file://" + (p || "").replace(/ /g, "%20"); }

    Rectangle { anchors.fill: parent; color: Theme.overlayScrim }
    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Loader {
        active: true
        anchors.centerIn: parent
        onLoaded: { Flavours.refresh(); Wallpaper.refresh(); Updates.refresh(); SysInfo.refresh(); }

        sourceComponent: Rectangle {
            id: bubble
            width: Math.min(800, win.width - 80)
            height: Math.min(560, win.height - 120)
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
                    // round the left corners to match the panel
                    topLeftRadius: Theme.radiusLarge
                    bottomLeftRadius: Theme.radiusLarge

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

                        NavItem { icon: "wallpaper"; label: "Wallpaper"; sect: "wallpaper" }
                        NavItem { icon: "palette"; label: "Theme"; sect: "theme" }
                        NavItem { icon: "tune"; label: "Device"; sect: "device" }
                        NavItem { icon: "info"; label: "About"; sect: "about" }

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.outline }

                // ── Content pane ────────────────────────────────────────────
                Item {
                    id: pane
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 14
                        z: 3
                        width: 30; height: 30; radius: 15
                        color: closeMa.containsMouse ? Theme.hover : Theme.surfaceHigh
                        MaterialIcon { anchors.centerIn: parent; icon: "close"; size: 18; color: Theme.text }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.closeAll() }
                    }

                    // ===== Wallpaper =====
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 14
                        visible: win.section === "wallpaper"
                        onVisibleChanged: if (visible) Wallpaper.refresh()

                        Text { text: "Wallpaper"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold }

                        Text {
                            Layout.fillWidth: true
                            visible: Wallpaper.walls.length === 0
                            text: "No images found in\n" + Wallpaper.dir + "\n\nAdd images there, or set $QUICKSHELL_WALLPAPERS."
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.Wrap
                        }

                        GridView {
                            id: wpGrid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: Wallpaper.walls.length > 0
                            clip: true
                            model: Wallpaper.walls
                            cellWidth: Math.floor(width / 3)
                            cellHeight: Math.round(cellWidth * 0.62)
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Item {
                                required property var modelData
                                width: wpGrid.cellWidth
                                height: wpGrid.cellHeight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    radius: Theme.radiusSmall
                                    color: Theme.surfaceHigh
                                    clip: true
                                    readonly property bool sel: Wallpaper.current === modelData
                                    border.width: sel || wpHover.hovered ? 3 : 0
                                    border.color: sel ? Theme.accent : Theme.outlineStrong
                                    Image {
                                        anchors.fill: parent
                                        source: win.fileUrl(modelData)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        sourceSize.width: 300
                                        sourceSize.height: 180
                                    }
                                    HoverHandler { id: wpHover }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpaper.apply(modelData) }
                                }
                            }
                        }
                    }

                    // ===== Theme =====
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 12
                        visible: win.section === "theme"

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.rightMargin: 46   // keep the switch clear of the close (X) button
                            Text { Layout.fillWidth: true; text: "Theme"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold }
                            // light / dark switch, top-right
                            Rectangle {
                                width: modeRow.implicitWidth + 24
                                height: 34
                                radius: 17
                                color: modeMa.containsMouse ? Theme.hover : Theme.surfaceHigh
                                RowLayout {
                                    id: modeRow
                                    anchors.centerIn: parent
                                    spacing: 8
                                    MaterialIcon { icon: Flavours.mode === "light" ? "light_mode" : "dark_mode"; size: 18; color: Theme.text }
                                    Text { text: Flavours.mode === "light" ? "Light" : "Dark"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.Medium }
                                }
                                MouseArea { id: modeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Flavours.toggleMode() }
                            }
                        }

                        // search
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 20
                            color: Theme.surfaceHigh
                            border.width: tsearch.activeFocus ? 2 : 0
                            border.color: Theme.accent
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10
                                MaterialIcon { anchors.verticalCenter: parent.verticalCenter; icon: "search"; size: 18; color: Theme.textDim }
                                TextInput {
                                    id: tsearch
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 28
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    clip: true
                                    onTextChanged: win.themeQuery = text
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Search schemes…"
                                        color: Theme.textFaint
                                        font: tsearch.font
                                        visible: tsearch.text.length === 0
                                    }
                                }
                            }
                        }

                        ListView {
                            id: themeList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 3
                            model: win.filteredFamilies
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: Flavours.currentFamily === modelData
                                width: themeList.width
                                height: 40
                                radius: Theme.radiusSmall
                                color: sel ? Theme.surfaceHigh : (tRowMa.containsMouse ? Theme.hover : "transparent")

                                Text {
                                    anchors.left: parent.left; anchors.leftMargin: 14
                                    anchors.right: check.left; anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Flavours.title(modelData)
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: parent.sel ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                }
                                MaterialIcon {
                                    id: check
                                    anchors.right: parent.right; anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "check"; size: 18; color: Theme.accent
                                    visible: parent.sel
                                }
                                MouseArea { id: tRowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Flavours.applyFamily(modelData) }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: Flavours.families.length === 0
                            text: "No schemes — install `flavours` and add Base16 schemes."
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.Wrap
                        }
                    }

                    // ===== Device =====
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16
                        visible: win.section === "device"

                        Text { text: "Device"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold }

                        SectionLabel { text: "Updates" }
                        Rectangle {
                            Layout.fillWidth: true
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
                                        text: (Updates.checking || !Updates.checked) ? "Checking for updates…"
                                            : Updates.count > 0 ? (Updates.count + " update" + (Updates.count > 1 ? "s" : "") + " available")
                                            : "Up to date"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        font.weight: Font.Medium
                                    }
                                    Text { text: "xbps (Void Linux)"; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                                }
                                PillButton {
                                    label: Updates.syncing ? "Syncing…" : "Sync"
                                    onClicked: Updates.syncAndCheck()
                                }
                                PillButton {
                                    label: Updates.count > 0 ? "Update" : "Check"
                                    accent: Updates.count > 0
                                    onClicked: Updates.count > 0 ? Updates.update() : Updates.refresh()
                                }
                            }
                        }

                        SectionLabel { text: "Power" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            PowerBtn { icon: "lock"; label: "Lock"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl lock-session"]); } }
                            PowerBtn { icon: "bedtime"; label: "Sleep"; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]); } }
                            PowerBtn { icon: "logout"; label: "Sign out"; confirm: true; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl terminate-user \"$(id -un)\" || niri msg action quit -s"]); } }
                            PowerBtn { icon: "restart_alt"; label: "Restart"; confirm: true; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl reboot || systemctl reboot"]); } }
                            PowerBtn { icon: "power_settings_new"; label: "Off"; danger: true; confirm: true; onClicked: { ShellState.closeAll(); Quickshell.execDetached(["sh", "-c", "loginctl poweroff || systemctl poweroff"]); } }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ===== About =====
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16
                        visible: win.section === "about"

                        Text { text: "About"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold }

                        Rectangle {
                            Layout.fillWidth: true
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
                            text: "A Chrome OS–style desktop shell for Quickshell."
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.Wrap
                        }
                        Item { Layout.fillHeight: true }
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
        property bool confirm: false   // require a second click
        property bool armed: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 62
        radius: Theme.radius
        color: armed ? Theme.bad : (powMa.containsMouse ? Theme.hover : Theme.surfaceBright)
        Column {
            anchors.centerIn: parent
            spacing: 4
            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                icon: pb.icon; size: 22
                color: pb.armed ? "#ffffff" : (pb.danger ? Theme.bad : Theme.text)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pb.armed ? "Confirm?" : pb.label
                color: pb.armed ? "#ffffff" : Theme.textDim
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall
                font.weight: pb.armed ? Font.Bold : Font.Normal
            }
        }
        Timer { id: disarm; interval: 3000; onTriggered: pb.armed = false }
        MouseArea {
            id: powMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (pb.confirm && !pb.armed) { pb.armed = true; disarm.restart(); return; }
                pb.armed = false;
                pb.clicked();
            }
        }
    }
}
