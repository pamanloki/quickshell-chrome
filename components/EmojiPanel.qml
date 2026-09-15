import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * ChromeOS-style emoji picker. Search or browse by category; clicking an emoji
 * copies it to the clipboard (paste with Ctrl+V). Centered; scrim / Esc closes.
 * Needs a colour emoji font (e.g. Noto Color Emoji) installed to render glyphs.
 */
PanelWindow {
    id: picker

    WlrLayershell.namespace: "quickshell:emoji"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    Rectangle { anchors.fill: parent; color: Theme.overlayScrim }
    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Loader {
        active: true
        anchors.centerIn: parent
        onLoaded: item.focusSearch()

        sourceComponent: Rectangle {
            id: bubble
            width: 372
            height: 452
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline
            clip: true

            function focusSearch() { search.forceActiveFocus(); }

            property string q: ""
            property int cat: 0   // 0 = Recent, 1..N = categories[cat-1]

            readonly property var tabs: [{ icon: "schedule" }].concat(
                Emoji.categories.map(c => ({ icon: c.icon })))

            readonly property var model: q.trim().length > 0 ? Emoji.search(q)
                : cat === 0 ? Emoji.recent
                : Emoji.categories[cat - 1].items.map(it => it[0])

            Component.onCompleted: { scale = 0.96; opacity = 0; anim.start(); }
            ParallelAnimation {
                id: anim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Search box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: height / 2
                    color: Theme.surfaceHigh
                    border.width: search.activeFocus ? 2 : 0
                    border.color: Theme.accent

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 8
                        MaterialIcon { anchors.verticalCenter: parent.verticalCenter; icon: "search"; size: 18; color: Theme.textDim }
                        TextInput {
                            id: search
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 28
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            clip: true
                            selectByMouse: true
                            selectionColor: Theme.accent
                            onTextChanged: bubble.q = text
                            Keys.onEscapePressed: ShellState.closeAll()
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search emoji"
                                color: Theme.textFaint
                                font: search.font
                                visible: search.text.length === 0
                            }
                        }
                    }
                }

                // Category tabs (hidden while searching)
                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    visible: bubble.q.trim().length === 0
                    spacing: 1
                    Repeater {
                        model: bubble.tabs
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: (bubble.width - 28) / bubble.tabs.length
                            height: 34
                            radius: Theme.radiusSmall
                            color: bubble.cat === index ? Theme.surfaceHigh
                                 : (tabMa.containsMouse ? Theme.hover : "transparent")
                            MaterialIcon {
                                anchors.centerIn: parent
                                icon: modelData.icon
                                size: 19
                                color: bubble.cat === index ? Theme.accent : Theme.textDim
                            }
                            MouseArea {
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bubble.cat = index
                            }
                        }
                    }
                }

                // Section label
                Text {
                    text: bubble.q.trim().length > 0 ? "Results"
                        : bubble.cat === 0 ? "Recent"
                        : Emoji.categories[bubble.cat - 1].name
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }

                // Empty state
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    horizontalAlignment: Text.AlignHCenter
                    visible: bubble.model.length === 0
                    text: bubble.q.trim().length > 0 ? "No emoji found"
                        : "No recent emoji yet"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }

                // Emoji grid
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: bubble.model.length > 0
                    clip: true
                    cellWidth: (bubble.width - 28) / 7
                    cellHeight: cellWidth
                    model: bubble.model
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        required property var modelData   // emoji string
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: grid.cellWidth - 4
                            height: grid.cellHeight - 4
                            radius: Theme.radiusSmall
                            color: cellMa.containsMouse ? Theme.hover : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.modelData
                                font.pixelSize: 24
                            }
                            MouseArea {
                                id: cellMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Emoji.use(parent.parent.modelData); ShellState.closeAll(); }
                            }
                        }
                    }
                }
            }
        }
    }
}
