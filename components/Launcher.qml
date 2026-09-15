import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/config"
import "root:/services"

/**
 * ChromeOS "bubble launcher": a rounded surface above the launcher button with
 * a search field and a scrollable app grid built from installed .desktop files.
 * Type to filter, Enter launches the first result, Esc / click-away closes.
 */
PanelWindow {
    id: launcher

    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    property string query: ""

    function allApps() {
        const arr = DesktopEntries.applications?.values ?? [];
        return arr.filter(a => a && !a.noDisplay);
    }

    function results() {
        const q = query.trim().toLowerCase();
        let list = allApps();
        if (q.length > 0) {
            list = list.filter(a => {
                const n = (a.name || "").toLowerCase();
                const c = (a.comment || "").toLowerCase();
                const g = (a.genericName || "").toLowerCase();
                return n.indexOf(q) !== -1 || c.indexOf(q) !== -1 || g.indexOf(q) !== -1;
            });
            // rank name-prefix matches first
            list.sort((x, y) => {
                const xs = (x.name || "").toLowerCase().startsWith(q) ? 0 : 1;
                const ys = (y.name || "").toLowerCase().startsWith(q) ? 0 : 1;
                if (xs !== ys) return xs - ys;
                return (x.name || "").localeCompare(y.name || "");
            });
        } else {
            list = list.slice().sort((x, y) => (x.name || "").localeCompare(y.name || ""));
        }
        return list;
    }

    function launch(entry) {
        if (!entry) return;
        ShellState.closeAll();
        Apps.record(entry.id);
        entry.execute();
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Theme.overlayScrim
    }
    MouseArea {
        anchors.fill: parent
        onPressed: ShellState.closeAll()
    }

    // Esc to close
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.closeAll()
    }

    Loader {
        active: true
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.gap

        onLoaded: item.focusSearch()

        sourceComponent: Rectangle {
            id: bubble
            width: 712
            // Shared column width so the app grid (6 wide) lines up with the
            // Frequent row. Height fits the search box + frequent + 3 grid rows.
            readonly property int cellW: Math.floor((width - 40) / 6)
            implicitHeight: col.implicitHeight + 40
            height: implicitHeight
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline

            function focusSearch() { search.forceActiveFocus(); }

            // In-bubble right-click context menu (Open / Pin to shelf).
            property bool ctxOpen: false
            property var ctxEntry: null
            property real ctxX: 0
            property real ctxY: 0
            function openCtx(entry, srcItem, mx, my) {
                if (!entry) return;
                const p = srcItem.mapToItem(bubble, mx, my);
                ctxEntry = entry;
                ctxX = Math.max(8, Math.min(p.x, width - 196));
                ctxY = Math.max(8, Math.min(p.y, height - 92));
                ctxOpen = true;
            }

            transformOrigin: Item.BottomLeft
            Component.onCompleted: { scale = 0.94; opacity = 0; showAnim.start(); }
            ParallelAnimation {
                id: showAnim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }

            MouseArea { anchors.fill: parent }   // swallow scrim clicks

            ColumnLayout {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 16

                // Search box
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: height / 2
                    color: Theme.surfaceHigh
                    border.width: search.activeFocus ? 2 : 0
                    border.color: Theme.accent

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "search"
                            size: 22
                            color: Theme.textDim
                        }

                        TextInput {
                            id: search
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 34
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.Medium
                            clip: true
                            selectByMouse: true
                            selectionColor: Theme.accent

                            onTextChanged: launcher.query = text
                            Keys.onEscapePressed: ShellState.closeAll()
                            Keys.onReturnPressed: {
                                const r = launcher.results();
                                if (r.length > 0) launcher.launch(r[0]);
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search your apps"
                                color: Theme.textFaint
                                font: search.font
                                visible: search.text.length === 0
                            }
                        }
                    }
                }

                // Frequent apps (when not searching)
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: launcher.query.length === 0 && Apps.frequent(6).length > 0
                    spacing: 8
                    Text {
                        text: "Frequent"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.Medium
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: Apps.frequent(6)
                            delegate: Item {
                                required property var modelData
                                implicitWidth: bubble.cellW
                                implicitHeight: 96
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 96
                                    height: 84
                                    radius: Theme.radius
                                    color: "transparent"
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        IconImage {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 44; height: 44
                                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                            smooth: true
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 84
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name || ""
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSmall
                                            elide: Text.ElideRight
                                        }
                                    }
                                    StateLayer {
                                        radius: parent.radius
                                        onClicked: launcher.launch(modelData)
                                    }
                                    MouseArea {
                                        id: freqCtxMa
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        onClicked: (m) => bubble.openCtx(modelData, freqCtxMa, m.x, m.y)
                                    }
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                Text {
                    text: launcher.query.length > 0 ? "Apps" : "All apps"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }

                // App grid — 6 columns, 3 rows visible (scrolls for more)
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 3 * cellHeight
                    clip: true
                    cellWidth: bubble.cellW
                    cellHeight: 108
                    model: launcher.results()
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: cell
                        required property var modelData
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: 96
                            height: 96
                            radius: Theme.radius
                            color: "transparent"

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                IconImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 48
                                    height: 48
                                    source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                                    smooth: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 84
                                    horizontalAlignment: Text.AlignHCenter
                                    text: cell.modelData.name || ""
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                }
                            }

                            StateLayer {
                                radius: parent.radius
                                onClicked: launcher.launch(cell.modelData)
                            }
                            MouseArea {
                                id: gridCtxMa
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: (m) => bubble.openCtx(cell.modelData, gridCtxMa, m.x, m.y)
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: grid.count === 0
                    text: "No results for \"" + launcher.query + "\""
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            // Click-away layer for the context menu.
            MouseArea {
                anchors.fill: parent
                visible: bubble.ctxOpen
                z: 50
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: bubble.ctxOpen = false
            }

            // Right-click context menu (Open / Pin to shelf).
            Rectangle {
                visible: bubble.ctxOpen
                z: 51
                x: bubble.ctxX
                y: bubble.ctxY
                width: 188
                height: ctxCol.implicitHeight + 10
                radius: Theme.radius
                color: Theme.surfaceGlass
                border.width: 1
                border.color: Theme.outline

                Column {
                    id: ctxCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5
                    spacing: 1

                    LauncherCtxItem {
                        icon: "open_in_new"
                        label: "Open"
                        onTriggered: launcher.launch(bubble.ctxEntry)
                    }
                    LauncherCtxItem {
                        readonly property bool pinned:
                            bubble.ctxEntry ? DockConfig.isPinned(bubble.ctxEntry.id) : false
                        icon: pinned ? "keep_off" : "keep"
                        label: pinned ? "Unpin from shelf" : "Pin to shelf"
                        onTriggered: {
                            if (!bubble.ctxEntry) return;
                            if (pinned) DockConfig.unpin(bubble.ctxEntry.id);
                            else DockConfig.pin(bubble.ctxEntry.id);
                            bubble.ctxOpen = false;
                        }
                    }
                }
            }
        }
    }

    component LauncherCtxItem: Rectangle {
        property string icon: ""
        property string label: ""
        signal triggered()
        width: parent ? parent.width : 0
        height: 36
        radius: Theme.radiusSmall
        color: ctxItemMa.containsMouse ? Theme.hover : "transparent"

        MaterialIcon {
            id: ctxItemIcon
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            icon: parent.icon
            size: 18
            color: Theme.text
        }
        Text {
            anchors.left: ctxItemIcon.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }
        MouseArea {
            id: ctxItemMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }
}
