import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/config"

/**
 * ChromeOS "bubble launcher": a rounded surface above the launcher button with
 * a search field and a scrollable app grid built from installed .desktop files.
 * Type to filter, Enter launches the first result, Esc / click-away closes.
 */
PanelWindow {
    id: launcher
    required property var modelData
    screen: modelData

    visible: State.launcherOpen && (State.activeScreen === null || State.activeScreen === modelData)

    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

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
        State.closeAll();
        entry.execute();
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Theme.overlayScrim
    }
    MouseArea {
        anchors.fill: parent
        onClicked: State.closeAll()
    }

    Loader {
        active: launcher.visible
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.shelfHeight + Theme.gap

        onLoaded: item.focusSearch()

        sourceComponent: Rectangle {
            id: bubble
            width: 680
            height: 560
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline

            function focusSearch() { search.forceActiveFocus(); }

            transformOrigin: Item.BottomLeft
            Component.onCompleted: { scale = 0.94; opacity = 0; showAnim.start(); }
            ParallelAnimation {
                id: showAnim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }

            MouseArea { anchors.fill: parent }   // swallow scrim clicks

            ColumnLayout {
                anchors.fill: parent
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
                            clip: true
                            selectByMouse: true
                            selectionColor: Theme.accent

                            onTextChanged: launcher.query = text
                            Keys.onEscapePressed: State.closeAll()
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

                Text {
                    text: launcher.query.length > 0 ? "Apps" : "All apps"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }

                // App grid
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 112
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
        }
    }
}
